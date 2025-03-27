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
    def __init__(self, user_info: dict):
        edu_entitlement = user_info.get("edu_entitlement")
        self.edu_entitlement = edu_entitlement.split("#")[0] if edu_entitlement else None

    def get_local_username(self, sub: str):
        logger.info("Checking VO membership information for user with sub: %s", sub)

        for group in config["VO_enforcement"]:
            valid_group = (config["VO_enforcement"]["group_" + group].split("#")[0])
            if self.edu_entitlement == valid_group:
                logger.info("User with sub: %s is a valid member of a VO group", sub)
                local_username = config["VO_enforcement"]["username_" + group]
                return local_username

        logger.error("User does not meet VO membership requirements")
        return None
