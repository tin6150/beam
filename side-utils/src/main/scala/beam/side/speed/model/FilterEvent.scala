package beam.side.speed.model
import java.time.DayOfWeek

import org.matsim.core.utils.collections.Tuple

sealed trait FilterDTO {
  def filterType: String
}

sealed abstract class FilterEventAction {
  type FilterEvent <: FilterDTO
  type Filtered
}

object FilterEvent {
  case object AllHoursDaysEventAction extends FilterEventAction {
    override type FilterEvent = AllHoursDaysDTO
    override type Filtered = Unit
    type AllHoursDaysEventAction = AllHoursDaysEventAction.type
  }

  case object WeekDayEventAction extends FilterEventAction {
    override type FilterEvent = WeekDayDTO
    override type Filtered = DayOfWeek
    type WeekDayEventAction = WeekDayEventAction.type
  }

  case object HourEventAction extends FilterEventAction {
    override type FilterEvent = HourDTO
    override type Filtered = Int
    type HourEventAction = HourEventAction.type
  }

  case object WeekDayHourEventAction extends FilterEventAction {
    override type FilterEvent = WeekDayHourDTO
    override type Filtered = (DayOfWeek, Int)
    type WeekDayHourEventAction = WeekDayHourEventAction.type
  }
}

case class AllHoursDaysDTO(filterType: String) extends FilterDTO
case class WeekDayDTO(filterType: String) extends FilterDTO
case class HourDTO(filterType: String) extends FilterDTO
case class WeekDayHourDTO(filterType: String) extends FilterDTO
