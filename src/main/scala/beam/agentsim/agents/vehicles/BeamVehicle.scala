package beam.agentsim.agents.vehicles

import akka.actor.{ActorRef, Props}
import akka.pattern._
import beam.agentsim.Resource
import beam.agentsim.Resource.{AssignManager, TellManagerResourceIsAvailable}
import beam.agentsim.agents.BeamAgent.{AnyState, BeamAgentData, BeamAgentState, Error, Uninitialized}
import beam.agentsim.agents.TriggerUtils._
import beam.agentsim.agents.modalBehaviors.CancelReservationWithVehicle
import beam.agentsim.agents.vehicles.BeamVehicle._
import beam.agentsim.agents.vehicles.EnergyEconomyAttributes.Powertrain
import beam.agentsim.agents.{BeamAgent, InitializeTrigger, RemovePassengerFromTrip}
import beam.agentsim.events.AgentsimEventsBus.MatsimEvent
import beam.agentsim.events.SpaceTime
import beam.agentsim.events.resources.vehicle._
import beam.agentsim.events.resources.{ReservationError, ReservationErrorCode}
import beam.agentsim.scheduler.TriggerWithId
import beam.router.Modes.BeamMode
import beam.router.RoutingModel.BeamPath
import beam.sim.{BeamServices, HasServices}
import org.matsim.api.core.v01.Id
import org.matsim.api.core.v01.events.{PersonEntersVehicleEvent, PersonLeavesVehicleEvent}
import org.matsim.api.core.v01.population.Person
import org.matsim.utils.objectattributes.attributable.Attributes
import org.matsim.vehicles.{Vehicle, VehicleType}

import scala.collection.mutable.ListBuffer
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future

/**
  * @author dserdiuk
  */

abstract class Dimension

//object VehicleData {
//  case class VehicleDataImpl(vehicleTypeName: String, vehicleClassName: String,
//                             matSimVehicle: Vehicle, attributes: Attributes) extends VehicleData {
//    override def getType: VehicleType = matSimVehicle.getType
//
//    override def getId: Id[Vehicle] = matSimVehicle.getId
//  }
//
//}
//trait VehicleData extends BeamAgentData with Vehicle {
//
//}

trait BeamVehicleObject {
  def props(beamServices: BeamServices, vehicleId: Id[Vehicle], matSimVehicle: Vehicle, powertrain: Powertrain): Props
}

object BeamVehicle {

  val ActorPrefixName = "vehicle-"

  case class BeamVehicleIdAndRef(id: Id[Vehicle], ref: ActorRef)

  object BeamVehicleIdAndRef {
    def apply(tup: (Id[Vehicle], ActorRef)): BeamVehicleIdAndRef = new BeamVehicleIdAndRef(tup._1, tup._2)
  }

  case object Moving extends BeamAgentState

  case object Idle extends BeamAgentState


  def energyPerUnitByType(vehicleTypeId: Id[VehicleType]): Double = {
    //TODO: add energy type registry
    0.0
  }

  def noSpecialChars(theString: String) = theString.replaceAll("[\\\\|\\\\^]+", ":")

  def buildActorName(matsimVehicle: Vehicle): String = {
    s"$ActorPrefixName${matsimVehicle.getType.getDescription.replaceAll(" ", "_")}-${noSpecialChars(matsimVehicle.getId.toString)}"
  }


  case class VehicleLocationRequest(time: Double)

  case class VehicleLocationResponse(vehicleId: Id[Vehicle], spaceTime: Future[SpaceTime])

  case class AlightingConfirmation(vehicleId: Id[Vehicle])

  case class BoardingConfirmation(vehicleId: Id[Vehicle])

  case class BecomeDriver(tick: Double, driver: Id[_], passengerSchedule: Option[PassengerSchedule] = None)

  case class UnbecomeDriver(tick: Double, driver: Id[_])

  case class BecomeDriverSuccess(passengerSchedule: Option[PassengerSchedule], vehicle: TempVehicle)

  case class BecomeDriverSuccessAck(id: Id[Vehicle])

  case class DriverAlreadyAssigned(vehicleId: Id[Vehicle], currentDriver: ActorRef)

  case class EnterVehicle(tick: Double, passengerVehicle: VehiclePersonId)

  case class ExitVehicle(tick: Double, passengerVehicle: VehiclePersonId)

  case class VehicleCapacityExceeded(vehicleId: Id[Vehicle]) extends ReservationError {
    override def errorCode: ReservationErrorCode = ReservationErrorCode.ResourceCapacityExhausted
  }

  case class AppendToTrajectory(beamPath: BeamPath)

  case class StreetVehicle(id: Id[Vehicle], location: SpaceTime, mode: BeamMode, asDriver: Boolean)

  case class SetCarrier(carrierVehicleId: Id[Vehicle])

  case class ClearCarrier()

}


/**
  * Defines common behavior for any vehicle. Communicate with PersonAgent
  * VehicleManager.
  * Passenger and driver can EnterVehicle and LeaveVehicle
  */
trait BeamVehicle extends BeamAgent[BeamAgentData] with Resource[Vehicle] with HasServices with Vehicle {
  override val id: Id[Vehicle]

  override def logPrefix(): String = s"BeamVehicle:$id "

  def matSimVehicle: Vehicle

  def attributes: Attributes

  def vehicleTypeName: String

  def vehicleClassName: String

  val vehicleId: Id[Vehicle]
  val data: BeamAgentData
  var powerTrain: Powertrain

  /**
    * The vehicle that is carrying this one. Like ferry or truck may carry a car and like a car carries a human body.
    */
  var carrier: Option[ActorRef] = None
  var driver: Option[ActorRef] = None
  /**
    * The actor managing this Vehicle
    */
  override var manager: Option[ActorRef] = None
  var passengers: ListBuffer[Id[Vehicle]] = ListBuffer()
  var lastVisited: SpaceTime = SpaceTime.zero
  var pendingReservations: List[ReservationRequest] = List[ReservationRequest]()

  def location(time: Double): Future[SpaceTime] = {
    carrier match {
      case Some(carrierVehicle) =>
        (carrierVehicle ? VehicleLocationRequest(time)).mapTo[SpaceTime].recover[SpaceTime] {
          case error: Throwable =>
            log.warning(s"Failed to get location from carrier ${carrierVehicle.path.name}. ", error)
            lastVisited
        }
      case None =>
        if (time > lastVisited.time) {
          logWarn(s"Requested time $time is in future. return lastVisited")
        }
        Future.successful(lastVisited)
    }
  }

  def setDriver(newDriver: ActorRef): Unit = {
    driver = Some(newDriver)
  }

  when(Idle) {
    case ev@Event(_, _) =>
      handleEvent(stateName, ev)
    case msg@_ =>
      val errMsg = s"From state Idle: Unrecognized message ${msg}"
      logError(errMsg)
      goto(Error) using stateData.copy(errorReason = Some(errMsg))
  }
  when(Moving) {
    case ev@Event(_, _) =>
      handleEvent(stateName, ev)
    case msg@_ =>
      val errMsg = s"From state Moving: Unrecognized message ${msg}"
      logError(errMsg)
      goto(Error) using stateData.copy(errorReason = Some(errMsg))
  }

  chainedWhen(Uninitialized) {
    case Event(AssignManager(managerRef), _) =>
      manager = Some(managerRef)
      stay()
    case Event(TriggerWithId(InitializeTrigger(tick), triggerId), _) =>
      log.debug(s" $id has been initialized, going to Idle state")
      goto(Idle) replying completed(triggerId)
  }

  private def sendPendingReservations(driverActor: ActorRef) = {
    if (pendingReservations.nonEmpty) {
      log.info(s"Sending pending ${pendingReservations.size} reservation request(s) to driver ${driverActor.path.name}")
      pendingReservations.foreach { reservation =>
        driverActor ! ReservationRequestWithVehicle(reservation, id)
      }
      pendingReservations = List()
    }
  }

  chainedWhen(Idle) {

    case Event(BecomeDriver(tick, newDriver, newPassengerSchedule), _) =>
      if (driver.isEmpty || driver.get == beamServices.agentRefs(newDriver.toString)) {
        if (driver.isEmpty) {
          driver = Some(beamServices.agentRefs(newDriver.toString))
          newDriver match {
            case personId: Id[Person] => beamServices.agentSimEventsBus.publish(new PersonEntersVehicleEvent(tick, personId, id))
            case _ =>
          }
        }
        // Important Note: the following works (asynchronously processing pending res's and then notifying driver of success)
        // only because we throw an exception when BecomeDriver fails. In other words, if the requesting
        // driver must register Success before assuming she is the driver, then we cannot send the PendingReservations as currently implemented
        // because that driver would not be ready to receive.
        val driverActor = driver.get
        sendPendingReservations(driverActor)
        driverActor ! BecomeDriverSuccess(newPassengerSchedule, id)
      } else {
        //TODO throwing an excpetion is the simplest approach b/c agents need not wait for confirmation before assuming they are drivers, but futur versions of BEAM may seek to be robust to this condition
        throw new RuntimeException(s"BeamAgent $newDriver attempted to become driver of vehicle $id but driver ${driver.get} already assigned.")
        //        val beamAgent = sender()
        //        beamAgent ! DriverAlreadyAssigned(id, driver.get)
      }
      stay()
    case Event(ModifyPassengerSchedule(newPassengerSchedule, requestId), info) =>
      driver.get ! ModifyPassengerSchedule(newPassengerSchedule, requestId)
      stay()
    case Event(ModifyPassengerScheduleAck(requestId), info) =>
      driver.get ! ModifyPassengerScheduleAck(requestId)
      stay()

    case Event(TellManagerResourceIsAvailable(whenWhere: SpaceTime), _) =>
      notifyManagerResourceIsAvailable(whenWhere)
      stay()
    case Event(UnbecomeDriver(tick, theDriver), info) =>
      if (driver.isEmpty) {
        //TODO throwing an excpetion is the simplest approach b/c agents need not wait for confirmation before assuming they are no longer drivers, but futur versions of BEAM may seek to be robust to this condition
        throw new RuntimeException(s"BeamAgent $theDriver attempted to Unbecome driver of vehicle $id but no driver in currently assigned.")
      } else {
        driver = None
        theDriver match {
          case personId: Id[Person] => beamServices.agentSimEventsBus.publish(MatsimEvent(new PersonLeavesVehicleEvent(tick, personId, id)))
          case _ =>
        }
      }
      stay()
  }

  chainedWhen(AnyState) {
    case Event(VehicleLocationRequest(time), _) =>
      sender() ! VehicleLocationResponse(id, location(time))
      stay()
    case Event(SetCarrier(carrierVehicleId), _) =>
      carrier = beamServices.vehicleRefs.get(carrierVehicleId)
      stay()
    case Event(ClearCarrier, _) =>
      carrier = None
      stay()
    case Event(AppendToTrajectory(newSegments), info) =>
      lastVisited = newSegments.getEndPoint()
      stay()
    case Event(a: RemovePassengerFromTrip, _) => {
      driver.foreach { d =>
        d ! a
      }
      stay()
    }
    case Event(req: CancelReservationWithVehicle, _) => {
      pendingReservations = pendingReservations.filterNot(x => x.passengerVehiclePersonId.equals(req.vehiclePersonId))
      driver.foreach { d =>
        d ! RemovePassengerFromTrip(req.vehiclePersonId)
      }
      stay()
    }

    case Event(request: ReservationRequest, _) =>
      driver match {
        case Some(driverActor) =>
          driverActor ! ReservationRequestWithVehicle(request, id)
        case None =>
          pendingReservations = pendingReservations :+ request
      }
      stay()
    case Event(any, _) =>
      logError(s"Unhandled event: $id $any $data")
      stay()
  }
}

case class VehicleStack(nestedVehicles: Vector[Id[Vehicle]] = Vector()) {
  def isEmpty = nestedVehicles.isEmpty

  def pushIfNew(vehicle: Id[Vehicle]) = {
    if (nestedVehicles.nonEmpty && nestedVehicles.head == vehicle) {
      VehicleStack(nestedVehicles)
    } else {
      VehicleStack(vehicle +: nestedVehicles)
    }
  }

  def penultimateVehicle(): Id[Vehicle] = {
    if (nestedVehicles.size < 2) throw new RuntimeException("Attempted to access penultimate vehicle when 1 or 0 are in the vehicle stack.")
    nestedVehicles(1)
  }

  def outermostVehicle(): Id[Vehicle] = {
    nestedVehicles(0)
  }

  def pop(): VehicleStack = {
    VehicleStack(nestedVehicles.tail)
  }
}


