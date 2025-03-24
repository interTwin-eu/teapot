import configparser
import logging

from fastapi import HTTPException

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
    @staticmethod
    def get_vo_info(sub: str, user_info: dict):
        logger.info("Checking VO info for user with sub: %s", sub)
        edu_entitlement = user_info.get("edu_entitlement")

        valid_vo_groups = config["VO_enforcement"]["group_membership"].split(", ")

        if edu_entitlement in valid_vo_groups:
            logger.info("User with sub: %s is a valid member of a VO group", sub)
            return True
        else:
            logger.warning(
                "User with sub: %s does not belong to any valid VO group", sub
            )
            return False

    @staticmethod
    def get_local_username(VO_member):
        if VO_member is True:
            local_username = config["VO_enforcement"]["username"]
            return local_username
        else:
            logger.error("User does not meet VO membership requirements")
            raise HTTPException(
                status_code=403, detail="User does not meet VO membership requirements."
            )
