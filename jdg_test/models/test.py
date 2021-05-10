# -*- coding: utf-8 -*-

from odoo import api, models, fields


class TestUsers(models.Model):
    _name = 'jd.test.users'
    _description = "test"

    login = fields.Char(string='账号')
    password = fields.Char(string='密码')

    def create_user(self):
        pass
