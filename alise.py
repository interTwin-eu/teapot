import configparser
import hashlib
import logging

import requests

config = configparser.ConfigParser(interpolation=configparser.ExtendedInterpolation())
config.read("/etc/teapot/config.ini")

# logging
logging.basicConfig(
    filename=config["Teapot"]["log_location"],
    encoding="utf-8",
    filemode="a",
    format="%(asctime)s %(levelname)s %(message)s",
    datefmt="%Y-%m-%d %H:%M",
    level=config["Teapot"]["log_level"],
)
logger = logging.getLogger(__name__)


class Alise:
    def __init__(self):
        self.apikey = config["ALISE"]["APIKEY"]
        self.alise_url = config["ALISE"]["INSTANCE"]
        self.issuer = config["ALISE"]["ISSUER"]
        self.site = config["ALISE"]["COMPUTING_CENTRE"]

    @staticmethod
    def hashencode(iss):
        hash_method = "sha1"
        hash_function = getattr(hashlib, hash_method)()

        if not iss:
            logger.error("Error: input string for issuer is empty.")
            return None
        else:
            for letter in iss[0:]:
                hash_function.update(letter.encode())
                hash = hash_function.hexdigest()
            return hash

    @staticmethod
    def urlencode(sub):
        try:
            from urllib.parse import quote_plus
        except ImportError:
            from urllib import quote_plus

        if not sub:
            logger.error("Error: input string for subject claim is empty.")
            return None
        else:
            result = ""
            for letter in sub[0:]:
                result += quote_plus(letter)
            return result

    def get_local_username(self, subject_claim):
        hash1 = Alise.hashencode(self.issuer)
        hash2 = Alise.urlencode(subject_claim)
        link = (
            self.alise_url
            + "/api/v1/target/"
            + self.site
            + "/mapping/issuer/"
            + hash1
            + "/user/"
            + hash2
            + "?apikey="
            + self.apikey
        )

        logger.debug("Assembled ALISE API URL is %s", link)
        try:
            response = requests.get(link, timeout=20)
        except ConnectionError as e:
            logger.error("Link to the ALISE instance is incorrect, %s", e)
        response_json = response.json()
        if response_json["internal"]["username"]:
            return response_json["internal"]["username"]
        else:
            logger.error(
                "The username could not be retrieved. The give error message is %s",
                response_json["detail"]["message"],
            )
            return None
