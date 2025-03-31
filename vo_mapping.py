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


class VO_mapping:
    def __init__(self, eduperson_entitlement):
        self.eduperson_entitlement = []
        for entitlement in eduperson_entitlement:
            self.eduperson_entitlement.append(
                entitlement.split("#")[0] if entitlement else None
            )
        logger.debug(
            "User's eduperson entitlements after the hash has been removed is %s",
            self.eduperson_entitlement,
        )

    def get_local_username(self, sub: str):
        logger.info("Checking VO membership information for user with sub: %s", sub)
        for entitlement in self.eduperson_entitlement:
            for group in config["VO_enforcement"]:
                valid_group = config["VO_enforcement"][group].split("#")[0]
                if entitlement == valid_group:
                    logger.info(
                        "User with sub %s is a member of a VO group %s",
                        sub, valid_group
                    )
                    group_tag = group.split("_")[1]
                    local_username = config["VO_enforcement"]["username_" + group_tag] or None
                    logger.info(
                        "The local group account for the VO group %s is %s ",
                        entitlement,
                        local_username,
                    )
                return local_username

        logger.error("User does not meet VO membership requirements")
        return None
