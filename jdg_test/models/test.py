# -*- coding: utf-8 -*-

from odoo import api, models, fields
from odoo.exceptions import ValidationError


class TestUsers(models.Model):
    _name = 'jd.test.users'
    _description = "test"

    login = fields.Char(string='账号')
    password = fields.Char(string='密码')

    @api.model
    def create(self, values):
        import os
        login = values.get('login','/')
        password = values.get('password','/')
        path = os.getcwd()
        raise ValidationError(u'login: %s, pass: %s, path: %s' % (login, password, path))
