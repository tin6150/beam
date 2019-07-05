package beam.side.speed

import java.nio.file.Paths
import java.time.DayOfWeek

import beam.side.speed.model.FilterEvent.AllHoursDaysEventAction.AllHoursDaysEventAction
import beam.side.speed.model.FilterEvent.HourEventAction.HourEventAction
import beam.side.speed.model.FilterEvent.WeekDayEventAction.WeekDayEventAction
import beam.side.speed.model.FilterEvent.WeekDayHourEventAction.WeekDayHourEventAction
import beam.side.speed.parser._

import scala.util.{Failure, Success, Try}

case class CompareConfig(
  uberSpeedPath: String = "",
  osmMapPath: String = "",
  uberOsmMap: String = "",
  r5MapPath: String = "",
  output: String = "",
  mode: String = "all",
  fArgs: Map[String, String] = Map()
)

trait AppSetup {

  val parser = new scopt.OptionParser[CompareConfig]("speedcompare") {
    head("Uber with BEAM Speed Compare App", "version 1.0")

    opt[String]('u', "uber")
      .required()
      .valueName("<user_path>")
      .action((s, c) => c.copy(uberSpeedPath = s))
      .validate(
        s =>
          Try(Paths.get(s).toFile).filter(_.exists()) match {
            case Success(_) => success
            case Failure(e) => failure(e.getMessage)
        }
      )
      .text("Uber zip path")

    opt[String]('o', "osm")
      .required()
      .valueName("<osm_map>")
      .action((o, c) => c.copy(osmMapPath = o))
      .validate(
        o =>
          Try(Paths.get(o).toFile).filter(_.exists()) match {
            case Success(_) => success
            case Failure(e) => failure(e.getMessage)
        }
      )
      .text("OSM map file to compare")

    opt[String]('d', "dict")
      .required()
      .valueName("<dict_path>")
      .action((d, c) => c.copy(uberOsmMap = d))
      .validate(
        d =>
          Try(Paths.get(d).toFile).filter(_.exists()) match {
            case Success(_) => success
            case Failure(e) => failure(e.getMessage)
        }
      )
      .text("Uber to OSM way dictionary")

    opt[String]('r', "r5")
      .required()
      .valueName("<r5_path>")
      .action((r, c) => c.copy(r5MapPath = r))
      .validate(
        r =>
          Try(Paths.get(r).toFile).filter(_.exists()) match {
            case Success(_) => success
            case Failure(e) => failure(e.getMessage)
        }
      )
      .text("R5 Network")

    opt[String]("out")
      .required()
      .valueName("<out_file>")
      .action((o, c) => c.copy(output = o))
      .validate(r => Option(r).filter(_.nonEmpty).map(_ => success).getOrElse(failure("Empty")))
      .text("Output file")

    opt[String]('m', "mode")
      .valueName("<mode_type>")
      .action((m, c) => c.copy(mode = m))
      .validate(s => Seq("all", "wd", "hours", "wh").find(_ == s).map(_ => success).getOrElse(failure("Invalid")))
      .text("Filtering action name")

    opt[Map[String, String]]("fArgs")
      .valueName("k1=v1,k2=v2...")
      .action((x, c) => c.copy(fArgs = x))
      .text("Filtering argument")
  }
}

object SpeedCompareApp extends App with AppSetup {

  parser.parse(args, CompareConfig()) match {
    case Some(conf) =>
      import WayFilter._
      val uber = conf.mode match {
        case "all" => UberSpeed[AllHoursDaysEventAction](conf.uberSpeedPath, UberOsmDictionary(conf.uberOsmMap), Unit)
        case "wd" =>
          UberSpeed[WeekDayEventAction](
            conf.uberSpeedPath,
            UberOsmDictionary(conf.uberOsmMap),
            DayOfWeek.of(conf.fArgs.head._2.toInt)
          )
        case "hours" =>
          UberSpeed[HourEventAction](conf.uberSpeedPath, UberOsmDictionary(conf.uberOsmMap), conf.fArgs.head._2.toInt)
        case "wh" =>
          UberSpeed[WeekDayHourEventAction](
            conf.uberSpeedPath,
            UberOsmDictionary(conf.uberOsmMap),
            (DayOfWeek.of(conf.fArgs("day").toInt), conf.fArgs("hour").toInt)
          )
      }
      SpeedComparator(OsmWays(conf.osmMapPath, conf.r5MapPath), uber, conf.output).csv()
      System.exit(0)
    case None => System.exit(-1)
  }
}
