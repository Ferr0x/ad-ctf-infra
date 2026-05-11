#!/usr/bin/env python3

import sys

from bandiera_lib import *


class Checker(BaseChecker):
    vulns: int = 1
    timeout: int = 5
    uses_attack_data: bool = True

    def __init__(self, *args, **kwargs):
        super(Checker, self).__init__(*args, **kwargs)
        self.mch = CheckMachine(self)

    def action(self, action, *args, **kwargs):
        try:
            super(Checker, self).action(action, *args, **kwargs)
        except requests.exceptions.ConnectionError:
            self.cquit(Status.DOWN, 'Connection error', 'Got requests connection error')

    def check(self):
        value = rnd_string(10)

        flag_id = self.mch.put_bandiera(value)
        get_value = self.mch.get_bandiera(flag_id, Status.MUMBLE)

        self.assert_eq(get_value, value, "Bandiera value is invalid")

        self.cquit(Status.OK)

    def put(self, flag_id: str, flag: str, vuln: str):
        flag_id = self.mch.put_bandiera(flag)
        self.cquit(Status.OK, str(flag_id))

    def get(self, flag_id: str, flag: str, vuln: str):
        value = self.mch.get_bandiera(int(flag_id), Status.CORRUPT)
        self.assert_eq(value, flag, "Bandiera value is invalid", Status.CORRUPT)
        self.cquit(Status.OK)


if __name__ == '__main__':
    c = Checker(sys.argv[2])

    try:
        c.action(sys.argv[1], *sys.argv[3:])
    except c.get_check_finished_exception():
        cquit(Status(c.status), c.public, c.private)
