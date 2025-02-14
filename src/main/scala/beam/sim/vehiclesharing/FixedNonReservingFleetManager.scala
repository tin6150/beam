package beam.sim.vehiclesharing

import akka.actor.Status.Success
import akka.actor.{ActorLogging, ActorRef, Stash}
import akka.pattern.pipe
import akka.util.Timeout
import beam.agentsim.Resource.{Boarded, NotAvailable, NotifyVehicleIdle, TryToBoardVehicle}
import beam.agentsim.agents.InitializeTrigger
import beam.agentsim.agents.household.HouseholdActor._
import beam.agentsim.agents.modalbehaviors.DrivesVehicle.Token
import beam.agentsim.agents.vehicles.EnergyEconomyAttributes.Powertrain
import beam.agentsim.agents.vehicles.VehicleProtocol.StreetVehicle
import beam.agentsim.agents.vehicles.{BeamVehicle, BeamVehicleType, VehicleManager}
import beam.agentsim.events.SpaceTime
import beam.agentsim.infrastructure.{ParkingInquiry, ParkingInquiryResponse}
import beam.agentsim.scheduler.BeamAgentScheduler.CompletionNotice
import beam.agentsim.scheduler.Trigger.TriggerWithId
import beam.sim.BeamServices
import beam.sim.config.BeamConfig.Beam.Debug
import beam.utils.logging.LoggingMessageActor
import beam.utils.logging.pattern.ask
import com.vividsolutions.jts.geom.{Coordinate, Envelope}
import com.vividsolutions.jts.index.quadtree.Quadtree
import org.matsim.api.core.v01.{Coord, Id}
import org.matsim.core.utils.geometry.CoordUtils

import java.util.concurrent.TimeUnit
import scala.collection.JavaConverters._
import scala.collection.mutable
import scala.concurrent.{ExecutionContext, Future}
import scala.util.Random

private[vehiclesharing] class FixedNonReservingFleetManager(
  val vehicleManagerId: Id[VehicleManager],
  val parkingNetworkManager: ActorRef,
  val chargingNetworkManager: ActorRef,
  val locations: Iterable[Coord],
  val vehicleType: BeamVehicleType,
  val mainScheduler: ActorRef,
  val beamServices: BeamServices,
  val maxWalkingDistance: Int,
  val repositionAlgorithmType: Option[RepositionAlgorithmType] = None
) extends LoggingMessageActor
    with ActorLogging
    with Stash
    with RepositionManager {

  private implicit val timeout: Timeout = Timeout(50000, TimeUnit.SECONDS)
  private implicit val executionContext: ExecutionContext = context.dispatcher
  private implicit val debug: Debug = beamServices.beamConfig.beam.debug

  private val rand: Random = new Random(beamServices.beamConfig.matsim.modules.global.randomSeed)

  private val vehicles = (locations.zipWithIndex map { case (location, ix) =>
    val vehicle = new BeamVehicle(
      Id.createVehicleId(self.path.name + "-" + ix),
      new Powertrain(0.0),
      vehicleType,
      vehicleManagerId = vehicleManagerId,
      rand.nextInt()
    )
    vehicle.setManager(Some(self))
    vehicle.spaceTime = SpaceTime(location, 0)
    vehicle.id -> vehicle
  }).toMap

  private val availableVehicles = mutable.Map.empty[Id[BeamVehicle], BeamVehicle]
  private val availableVehiclesIndex = new Quadtree

  override def loggedReceive: Receive = super[RepositionManager].loggedReceive orElse { // Reposition
    case TriggerWithId(InitializeTrigger(_), triggerId) =>
      // Pipe my cars through the parking manager
      // and complete initialization only when I got them all.
      Future
        .sequence(vehicles.values.map { veh =>
          veh.setManager(Some(self))
          val infrastructureManager = if (veh.isBEV || veh.isPHEV) chargingNetworkManager else parkingNetworkManager
          infrastructureManager ? ParkingInquiry
            .init(veh.spaceTime, "wherever", vehicleManagerId, triggerId = triggerId) flatMap {
            case ParkingInquiryResponse(stall, _, triggerId) =>
              veh.useParkingStall(stall)
              self ? ReleaseVehicleAndReply(veh, None, triggerId)
          }
        })
        .map(_ => CompletionNotice(triggerId, Vector()))
        .pipeTo(sender())

    case GetVehicleTypes(triggerId) =>
      sender() ! VehicleTypesResponse(vehicles.values.map(_.beamVehicleType).toSet, triggerId)
    case MobilityStatusInquiry(_, whenWhere, _, triggerId) =>
      // Search box: maxWalkingDistance meters around query location
      val boundingBox = new Envelope(new Coordinate(whenWhere.loc.getX, whenWhere.loc.getY))
      boundingBox.expandBy(maxWalkingDistance)

      val nearbyVehicles = availableVehiclesIndex.query(boundingBox).asScala.toVector.asInstanceOf[Vector[BeamVehicle]]
      nearbyVehicles.sortBy(veh => CoordUtils.calcEuclideanDistance(veh.spaceTime.loc, whenWhere.loc))
      sender ! MobilityStatusResponse(
        nearbyVehicles.take(5).map { vehicle =>
          Token(vehicle.id, self, vehicle)
        },
        triggerId
      )
      collectData(whenWhere.time, whenWhere.loc, RepositionManager.inquiry)

    case TryToBoardVehicle(token, who, triggerId) =>
      makeUnavailable(token.id, token.streetVehicle) match {
        case Some(vehicle) if token.streetVehicle.locationUTM == vehicle.spaceTime =>
          log.debug("Checked out " + vehicle.id)
          who ! Boarded(vehicle, triggerId)
          collectData(vehicle.spaceTime.time, vehicle.spaceTime.loc, RepositionManager.boarded)
        case _ =>
          who ! NotAvailable(triggerId)
      }

    case NotifyVehicleIdle(vId, whenWhere, _, _, _, _) =>
      makeTeleport(vId.asInstanceOf[Id[BeamVehicle]], whenWhere)

    case ReleaseVehicle(vehicle, _) =>
      makeAvailable(vehicle.id)
      collectData(vehicle.spaceTime.time, vehicle.spaceTime.loc, RepositionManager.release)

    case ReleaseVehicleAndReply(vehicle, _, triggerId) =>
      makeAvailable(vehicle.id)
      sender() ! Success(triggerId)
      collectData(vehicle.spaceTime.time, vehicle.spaceTime.loc, RepositionManager.release)
  }

  override def getId: Id[VehicleManager] = vehicleManagerId

  override def queryAvailableVehicles: List[BeamVehicle] =
    availableVehiclesIndex.queryAll().asScala.map(_.asInstanceOf[BeamVehicle]).toList
  override def getScheduler: ActorRef = mainScheduler
  override def getServices: BeamServices = beamServices
  def getRepositionAlgorithmType: Option[RepositionAlgorithmType] = repositionAlgorithmType
  override def getAvailableVehicles: Iterable[BeamVehicle] = availableVehicles.values

  override def makeAvailable(vehId: Id[BeamVehicle]): Boolean = {
    val vehicle = vehicles(vehId)
    availableVehicles += vehId -> vehicle
    availableVehiclesIndex.insert(
      new Envelope(new Coordinate(vehicle.spaceTime.loc.getX, vehicle.spaceTime.loc.getY)),
      vehicle
    )
    log.debug("Checked in " + vehId)
    true
  }

  override def makeUnavailable(vehId: Id[BeamVehicle], streetVehicle: StreetVehicle): Option[BeamVehicle] = {
    availableVehicles.get(vehId) match {
      case Some(vehicle) if streetVehicle.locationUTM == vehicle.spaceTime =>
        availableVehicles.remove(vehId)
        val removed = availableVehiclesIndex.remove(
          new Envelope(new Coordinate(vehicle.spaceTime.loc.getX, vehicle.spaceTime.loc.getY)),
          vehicle
        )
        if (!removed) {
          log.error("Didn't find a vehicle in my spatial index, at the location I thought it would be.")
        }
        log.debug("Booked " + vehId)
        Some(vehicle)
      case _ => None
    }
  }

  override def makeTeleport(vehId: Id[BeamVehicle], whenWhere: SpaceTime): Unit = {
    vehicles(vehId).spaceTime = whenWhere
    log.debug("updated vehicle {} with location {}", vehId, whenWhere)
  }
}
