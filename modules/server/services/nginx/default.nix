# This file is part of Nix++.
# Copyright (C) 2023 Leandro Emmanuel Reina Kiperman.
#
# Nix++ is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# Nix++ is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

{ ... } @ _inputs:
{ pkgs, ... }: {
  # Set some defaults
  config.services.nginx = {
    package = pkgs.nginxMainline;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    commonHttpConfig = ''
      gzip       on ;
      gunzip     on ;
      gzip_vary  on ;

      gzip_comp_level  5 ;
      gzip_min_length  256 ;
      gzip_buffers     16 8k ;
      gzip_proxied     any ;

      gzip_types
        application/javascript
        text/css
        text/html
        text/javascript
        text/js
        text/plain
        image/jpeg
        image/png
        image/svg+xml
        image/webp
      ;

      access_log  /var/log/nginx/access.log combined ;
      error_log   /var/log/nginx/error.log warn ;
    '';
  };
}
