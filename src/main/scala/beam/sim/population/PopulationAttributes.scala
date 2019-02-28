package beam.sim.population

import beam.agentsim.agents.vehicles.{BeamVehicle, BeamVehicleType}
import beam.router.Modes.BeamMode
import beam.router.Modes.BeamMode._
import beam.router.model.{BeamLeg, EmbodiedBeamLeg}
import org.matsim.api.core.v01.Id
import org.matsim.households.{Household, IncomeImpl}
import org.matsim.households.Income.IncomePeriod
import org.matsim.api.core.v01.population._
import beam.sim.BeamServices
import beam.agentsim.agents.modalbehaviors.ModeChoiceCalculator._
import beam.sim.config.BeamConfig.Beam.Agentsim.Agents.ModalBehaviors

import scala.collection.JavaConverters._
import scala.collection.mutable

sealed trait PopulationAttributes

case class AttributesOfIndividual(
  householdAttributes: HouseholdAttributes,
  modalityStyle: Option[String],
  isMale: Boolean,
  availableModes: Seq[BeamMode],
  valueOfTime: Double,
  age: Option[Int],
  income: Option[Double]
) extends PopulationAttributes {
  lazy val hasModalityStyle: Boolean = modalityStyle.nonEmpty
  // Get Value of Travel Time for a specific leg of a travel alternative:
  // If it is a car leg, we use link-specific multipliers, otherwise we just look at the entire leg travel time and mode
  def getVOT(embodiedBeamLeg: EmbodiedBeamLeg,
             modeMultipliers: mutable.Map[Option[BeamMode], Double],
             situationMultipliers: mutable.Map[(timeSensitivity,congestionLevel,roadwayType,automationLevel), Double],
             poolingMultipliers: mutable.Map[automationLevel, Double],
             beamServices: BeamServices,
             destinationActivity: Option[Activity]): Double = {
    val isWorkTrip = destinationActivity match {
      case None =>
        false
      case Some(activity) =>
        activity.getType().equalsIgnoreCase("work")
    }
    val vehicleAutomationLevel: automationLevel = getAutomationLevel(embodiedBeamLeg, beamServices)
    embodiedBeamLeg.beamLeg.mode match {
      case CAR              => getPathVotMultiplier(embodiedBeamLeg.beamLeg, situationMultipliers, beamServices, isWorkTrip, vehicleAutomationLevel)*
        getModeVotMultiplier(Option(embodiedBeamLeg.beamLeg.mode),modeMultipliers) *
        unitConversionVOTT(embodiedBeamLeg.beamLeg.duration)
      case RIDE_HAIL        => getModeVotMultiplier(Option(embodiedBeamLeg.beamLeg.mode),modeMultipliers) *
        unitConversionVOTT(embodiedBeamLeg.beamLeg.duration)
      case RIDE_HAIL_POOLED => getPooledFactor(embodiedBeamLeg, poolingMultipliers, beamServices) *
        getModeVotMultiplier(Option(embodiedBeamLeg.beamLeg.mode),modeMultipliers) *
        unitConversionVOTT(embodiedBeamLeg.beamLeg.duration)
      case _                => getModeVotMultiplier(Option(embodiedBeamLeg.beamLeg.mode), modeMultipliers) *
        unitConversionVOTT(embodiedBeamLeg.beamLeg.duration)
    }
  }

  private def getAutomationLevel(embodiedBeamLeg: EmbodiedBeamLeg, beamServices: BeamServices): automationLevel = {
    val vehicleAutomationLevel = beamServices.getDefaultAutomationLevel().getOrElse(beamServices.vehicleTypes(embodiedBeamLeg.beamVehicleTypeId).automationLevel.map(_.toInt))
    vehicleAutomationLevel match {
      case 3 => levelLE3
      case 4 => level4
      case 5 => level5
      case _ => levelLE3
    }

  }
  private def getPathVotMultiplier(beamLeg: BeamLeg,
                                   situationMultipliers: mutable.Map[(timeSensitivity,congestionLevel,roadwayType,automationLevel), Double],
                                   beamServices: BeamServices,
                                   isWorkTrip: Boolean,
                                   vehicleAutomationLevel: automationLevel): Double = {
    (beamLeg.travelPath.linkIds zip beamLeg.travelPath.linkTravelTime).map(
      x => getSituationMultiplier(x._1,x._2, isWorkTrip, situationMultipliers, vehicleAutomationLevel, beamServices) * x._2
    ).sum
  }

  // If it's not a car mode, send it over to beamServices to get the mode VOTT multiplier from config
  def unitConversionVOTT(duration: Double): Double = {
    valueOfTime / 3600 * duration
  }

  def getModeVotMultiplier(beamMode: Option[BeamMode], modeMultipliers: mutable.Map[Option[BeamMode], Double]): Double = {
    modeMultipliers.getOrElse(beamMode, 1.0)
  }

  private def getPooledFactor(embodiedBeamLeg: EmbodiedBeamLeg, poolingMultipliers: mutable.Map[automationLevel, Double], beamServices: BeamServices): Double = {
    val vehicleAutomationLevel = getAutomationLevel(embodiedBeamLeg, beamServices)
    poolingMultipliers.getOrElse(vehicleAutomationLevel, 1.0)
  }

  private def getLinkCharacteristics(linkID:Int, travelTime:Double, beamServices: BeamServices): (congestionLevel,roadwayType) = {
    val freeSpeed:Double = beamServices.networkHelper.getLink(linkID).get.getFreespeed()
    val currentSpeed:Double = beamServices.networkHelper.getLink(linkID).get.getLength() / travelTime
    if (currentSpeed < 0.5 * freeSpeed) {
      if (freeSpeed > 22) {
        (highCongestion,highway)
      } else {
        (highCongestion,nonHighway)
      }
    } else {
      if (freeSpeed > 22) {
        (lowCongestion,highway)
      } else {
        (lowCongestion,nonHighway)
      }
    }
  }

  private def getSituationMultiplier(linkID:Int,
                             travelTime:Double,
                             isWorkTrip: Boolean = true,
                             situationMultipliers: mutable.Map[(timeSensitivity,congestionLevel,roadwayType,automationLevel), Double],
                             vehicleAutomationLevel: automationLevel,
                             beamServices: BeamServices): Double = {
    val sensitivity: timeSensitivity = if (isWorkTrip) {
      highSensitivity
    } else {
      lowSensitivity
    }
    val (congestion,roadway) = getLinkCharacteristics(linkID, travelTime, beamServices)
    situationMultipliers.getOrElse((sensitivity,congestion,roadway,vehicleAutomationLevel),1.0)
  }

}

object AttributesOfIndividual {
  val EMPTY = AttributesOfIndividual(HouseholdAttributes.EMPTY, None, true, Seq(), 0.0, None, None)

}

case class HouseholdAttributes(
  householdIncome: Double,
  householdSize: Int,
  numCars: Int,
  numBikes: Int
) extends PopulationAttributes

object HouseholdAttributes {

  val EMPTY = HouseholdAttributes(0.0, 0, 0, 0)

  def apply(household: Household, vehicles: Map[Id[BeamVehicle], BeamVehicle]): HouseholdAttributes = {
    new HouseholdAttributes(
      Option(household.getIncome)
        .getOrElse(new IncomeImpl(0, IncomePeriod.year))
        .getIncome,
      household.getMemberIds.size(),
      household.getVehicleIds.asScala
        .map(id => vehicles(id))
        .count(_.beamVehicleType.id.toString.toLowerCase.contains("car")),
      household.getVehicleIds.asScala
        .map(id => vehicles(id))
        .count(_.beamVehicleType.id.toString.toLowerCase.contains("bike"))
    )
  }
}
