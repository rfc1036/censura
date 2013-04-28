#!/usr/bin/perl -c
# vim: shiftwidth=4 tabstop=4
#
# Copyright 2013 by Marco d'Itri <md@linux.it>.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This is a Plack application:
# plackup --server FCGI --listen /var/run/md/whoami.socket --env deployment /opt/censura/bin/whoami.psgi

use warnings;
use strict;

use Plack::Request;
use Plack::Builder;
use File::Slurp;

my $DB_Dir = '/dev/shm/whoami-ns';
my $Log_File = '/tmp/whoami-req.log';

##############################################################################
# smallest transparent 1x1 GIF image
sub gif_1x1() {
	"GIF89a\1\0\1\0\x80\0\0\xff\xff\xff\0\0\0\x21\xf9\x04\1\0\0\0\0\x2c"
	. "\0\0\0\0\1\0\1\0\0\2\2\x44\1\0\x3b"
}

##############################################################################
# a trivial 404 page
my $app_404 = sub {
	[ 404, ['Content-Type' => 'text/plain'], ["Nothing to see here...\n"] ]
};

##############################################################################
my $app_1x1 = sub {
	my $env = shift;
	my $req = Plack::Request->new($env);

	return $app_404->($env) if $req->path_info;
	return $app_404->($env) if $req->method !~ '^(?:GET|HEAD)$';

	my $ns = get_client_ns($env);
	log_client_ns($req->address, $ns, 'gif') if $ns;

	my $res = $req->new_response(200);
	$res->content_type('image/gif');
	$res->header('Cache-Control' => 'max-age=30');
	$res->body(gif_1x1);

	return $res->finalize;
};

##############################################################################
my $app_ns = sub {
	my $env = shift;
	my $req = Plack::Request->new($env);

	return $app_404->($env) if $req->path_info;
	return $app_404->($env) if $req->method !~ '^(?:GET|HEAD)$';

	my $ns = get_client_ns($env);
	log_client_ns($req->address, $ns, 'ns') if $ns;
	$ns ||= '';

	my $res = $req->new_response(200);
	$res->content_type('application/json');
	$res->header('Cache-Control' => 'max-age=30');
	$res->body(qq#{ "client": "# . $req->address . qq#", "ns": "$ns" }\n#);

	return $res->finalize;
};

##############################################################################
sub get_client_ns {
	my ($env) = @_;

	my $domain = $env->{HTTP_HOST};
	return '' if not $domain;
	#$domain =~ s/:\d+$//;

	my ($token) = $domain =~ /^([a-z0-9-]+)\./;
	return '' if not $token;
	
	my $value = read_file("$DB_Dir/$token") if -f "$DB_Dir/$token";
	return '' if not $value;
	chomp $value;
	return $value;
}

sub log_client_ns {
	my ($address, $ns, $what) = @_;

	return if not $Log_File;
	$what = $what ? " $what" : '';
	write_file($Log_File, { append => 1, err_mode => 'quiet' },
		time() . " $address $ns$what\n");
}

##############################################################################
builder {
	enable 'Head'; # must appear before ContentLength or that will be 0
	enable 'ContentLength';
	mount '/ns' => builder {
		enable 'JSONP', callback_key => 'jsonp';
		$app_ns;
	};
	mount '/1x1.gif' => $app_1x1;
	mount '/' => $app_404;
};

