assert = require 'assert'
request = require 'request'
promise = require 'bluebird'
extend = require('util')._extend
fs = require 'fs'


argv = require('minimist')(process.argv.slice(2))
if argv.h?
    console.log """
        -h view this help
        -a auth url
        -u username
        -p password
        -t tenant name
        -l loglevel (verbose, debug, info, warn)
    """
    return




getToken = () =>
    log.info 'Fetching Token', username:opts.username, password:opts.password, url:opts.url
    assert opts.username? or opts.password? or opts.url?, "Missing parameters"
    return new promise (fulfill, reject) =>
        rbody =
            auth:
                tenantName: opts.tenant
                passwordCredentials:
                    username: opts.username
                    password: opts.password

        options =
            url: opts.url + "/tokens"
            method: 'POST'
            body: rbody
            headers:
                'content-type': "application/json"
            json: true

        request options, (error,response, body) =>
            console.log "fetching token", body
            log.debug 'getToken: response to /token', error:error, body:body
            return reject error if error?
            opts.token = body.access.token.id
            opts.tenantid = body.access.token.tenant.id
            return fulfill opts

loadEntity = (options) =>
    return new promise (fulfill, reject) =>
        log.info 'loadEntity: Loading entities', options:options
        request options, (error, body, response) =>
            log.debug  'Response for load Entity', method:'loadEntity', error:error, response:response
            return reject error if error?
            return fulfill response


getAccounts = () =>
    return new promise (fulfill, reject) =>
        loadEntity  url:opts.nova+"/#{opts.tenantid}/servers", method:'GET', headers:{'X-Auth-Token': "#{opts.token}"}
        . then (resp) =>
            log.info "servers list", accounts:resp
            opts.accounts = (JSON.parse resp).servers
            return reject new Error "no servers found" if opts.accounts.length is 0
            console.log opts.accounts
            return fulfill "success"
        , (error) =>
            return reject error

deleteAccount = (account) =>
    return new promise (fulfill, reject) =>
        console.log "Deleting Server with id #{account.name}"
        loadEntity url:opts.nova+"/#{opts.tenantid}/servers/#{account.id}", method: 'DELETE', headers:"X-Auth-Token":"#{opts.token}"
        . then (resp) =>
            log.info "account deleted", resp:resp
            return fulfill "success"
        , (error) =>
            log.error "failed to delete server", error:error
            return reject error

deleteAccounts = () =>
    return new promise (fulfill, reject) =>

        log.info method:'Delete servers'
        opts.accounts.filter (account) =>
            deleteAccount account


opts =
    username: argv?.u ? 'username'
    password: argv?.p ? 'password'
    url:  argv?.a ? 'http://vhub3.dev.intercloud.net:5000/v2.0'
    tenant: argv?.t ? 'vsc'
    level: argv?.l ? 'info'
    nova:  argv?.n ? 'http://vhub3.dev.intercloud.net:8774/v2'

log = new (require 'bunyan')
        name: 'account-stress'
        streams: [path: "/tmp/openstack.log"]
        level: opts.level

console.log 'options passed in are ', opts

getToken()
. then (getAccounts)
. then (deleteAccounts)
. then (resp) =>
    console.log "success"
, (error) =>
    console.log "error ", error






