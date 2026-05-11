import requests
from checklib import *

PORT = 8181


class CheckMachine:
    @property
    def url(self):
        return f'http://{self.c.host}:{self.port}'

    def __init__(self, checker: BaseChecker):
        self.c = checker
        self.port = PORT

    def put_bandiera(self, value: str) -> id:
        url = f'{self.url}/bandiera'

        response = requests.post(url, json={"bandiera": value})

        data = self.c.get_json(response, "Invalid response on put_bandiera")
        self.c.assert_eq(type(data), dict, "Invalid response on put_bandiera")
        self.c.assert_in("id", data, "Invalid response on put_bandiera")
        self.c.assert_eq(type(data["id"]), int, "Invalid response on put_bandiera")
        return data["id"]

    def get_bandiera(self, id: int, status: Status) -> str:
        url = f'{self.url}/bandiera'

        response = requests.get(url, json={"id": id})

        data = self.c.get_json(response, "Invalid response on get_bandiera", status)
        self.c.assert_eq(type(data), dict, "Invalid response on get_bandiera", status)
        self.c.assert_in("bandiera", data, "Invalid response on get_bandiera", status)
        self.c.assert_eq(type(data["bandiera"]), str, "Invalid response on get_bandiera", status)
        self.c.assert_neq(data["bandiera"], "", "Can't get bandiera", status)

        return data["bandiera"]
