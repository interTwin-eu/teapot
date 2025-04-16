import configparser
import logging

config = configparser.ConfigParser(interpolation=configparser.ExtendedInterpolation())
config.read("/etc/teapot/config.ini")

logging.basicConfig(
    filename=config["Teapot"]["log_location"],
    encoding="utf-8",
    filemode="a",
    format="%(asctime)s %(levelname)s %(message)s",
    datefmt="%Y-%m-%d %H:%M",
    level=config["Teapot"]["log_level"],
)
logger = logging.getLogger(__name__)


class VOMapping:
    def __init__(self, eduperson_entitlement):
        self.eduperson_entitlement = [
            ent.split("#")[0] for ent in eduperson_entitlement if ent
        ]
        logger.debug(
            "User's eduperson entitlements after the hash has been removed are %s",
            self.eduperson_entitlement,
        )

    def get_local_username(self, sub: str):
        logger.info("Checking if the user with sub %s is a member of a specified VO", sub)
        for entitlement in self.eduperson_entitlement:
            for group in config["VO_enforcement"]:
                if group.startswith("group_"):
                    group_requirement = config["VO_enforcement"][group].split("#")[0]
                    if entitlement == group_requirement:
                        logger.info(
                            "User with sub %s is a member of the specified VO %s",
                            sub,
                            group_requirement,
                        )
                        parts = group.split("_", 1)
                        if len(parts) != 2:
                            logger.warning("Group %s is not named correctly", group)
                            continue
                        group_tag = parts[1]
                        try:
                            local_username = (
                                config["VO_enforcement"]["username_" + group_tag]
                            )
                            logger.info(
                                "The local group account mapped to VO group %s is %s ",
                                entitlement,
                                local_username,
                            )
                            return local_username
                        except KeyError:
                            logger.error(
                                "No local username mapping found for VO group %s."
                                 + "Username_%s not defined in config.",
                                entitlement,
                                group_tag,
                            )

        logger.error("User does not meet VO membership requirements")
        return None
