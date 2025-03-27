import configparser
import hashlib
import logging
from urllib.parse import quote_plus

import requests

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


class Alise:
    def __init__(self):
        self.apikey = config["ALISE"]["APIKEY"]
        self.alise_url = config["ALISE"]["INSTANCE"]
        self.site = config["ALISE"]["COMPUTING_CENTRE"]

    @staticmethod
    def hashencode(iss):
        """
        Generate a SHA-1 hash by iteratively updating the hash with each character
        of the given issuer string.

        This function takes an input string iss, hashes each character individually
        using SHA-1, and returns the final hexadecimal hash value. If the input string
        is empty, it logs an error and returns None.
        """
        hash_method = "sha1"
        hash_function = getattr(hashlib, hash_method)()

        if not iss:
            logger.error("Error: input string for issuer is empty.")
            return None

        hash_function.update(iss.encode())
        hash = hash_function.hexdigest()

        return hash

    @staticmethod
    def urlencode(sub):
        """
        URL-encode the given subject claim string.

        This function takes an input string sub, encodes it using quote_plus,
        and returns the encoded result. If the input is empty, it logs an error
        and returns None.
        """
        if not sub:
            logger.error("Error: input string for subject claim is empty.")
            return None
        else:
            return quote_plus(sub)

    def get_local_username(self, subject_claim, issuer):
        """
        Retrieve the local username from the ALISE API.

        This function constructs a request to the ALISE API by hashing the issuer
        and URL-encoding the subject_claim. It then sends a GET request to retrieve
        the corresponding local username. If the request fails or the response is
        invalid, it logs an error and returns None.
        """
        hash1 = Alise.hashencode(issuer)
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
            response.raise_for_status()  # Raise an HTTPError for 4xx/5xx responses
        except requests.ConnectionError as e:
            logger.error(
                "Can't connect to ALISE API. Network-related error was raised: %s", e
            )
            return None
        except requests.Timeout as e:
            logger.error("Can't connect to ALISE API. Request timed out: %s", e)
            return None
        except requests.RequestException as e:
            logger.error("An error occured during request to ALISE API: %s", e)
            return None
        except Exception as e:
            logger.error("Request to ALISE API raised an unexpected error: %s", e)
            return None

        try:
            response_json = response.json()
            local_username = response_json["internal"]["username"]
        except ValueError as e:
            logger.error("Decoding JSON has failed: %s", e)
            return None
        except Exception as e:
            logger.error("Local username not found in the json response: %s", e)
            return None

        return local_username
