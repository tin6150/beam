package beam.agentsim.agents.household

import java.util.concurrent.TimeUnit

import akka.actor.{ActorRef, ActorSystem}
import akka.testkit.{ImplicitSender, TestKit}
import akka.util.Timeout
import beam.agentsim.agents.modalBehaviors.ModeChoiceCalculator
import beam.router.r5.NetworkCoordinator
import beam.sim.BeamServices
import beam.sim.config.BeamConfig
import beam.utils.BeamConfigUtils
import com.typesafe.config.ConfigFactory
import org.matsim.api.core.v01.Id
import org.matsim.core.events.EventsManagerImpl
import org.matsim.households.Household
import org.matsim.vehicles.VehicleUtils
import org.scalatest.mockito.MockitoSugar
import org.mockito.Mockito._
import org.scalatest.{BeforeAndAfterAll, FunSpecLike}

class HouseholdActorSpec extends TestKit(ActorSystem("testsystem", ConfigFactory.parseString( """
  akka.loggers = ["akka.testkit.TestEventListener"]
  akka.log-dead-letters = 10
  """).withFallback(BeamConfigUtils.parseFileSubstitutingInputDirectory("test/input/beamville/beam.conf").resolve()))) with FunSpecLike
  with BeforeAndAfterAll with MockitoSugar with ImplicitSender{

  private implicit val timeout = Timeout(60, TimeUnit.SECONDS)
  val config = BeamConfig(system.settings.config)
  val eventsManager = new EventsManagerImpl()
  val services: BeamServices = {
    val theServices = mock[BeamServices]
//    when(theServices.householdRefs).thenReturn(collection.concurrent.TrieMap[Id[Household], ActorRef]())
    when(theServices.beamConfig).thenReturn(config)
//    when(theServices.modeChoiceCalculator).thenReturn(mock[ModeChoiceCalculator])
    theServices
  }
  private val networkCoordinator = new NetworkCoordinator(config, VehicleUtils.createVehiclesContainer())
  networkCoordinator.loadNetwork()


}
