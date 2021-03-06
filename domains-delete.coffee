assert = require 'assert'
request = require 'request'
promise = require 'bluebird'
extend = require('util')._extend
fs = require 'fs'


argv = require('minimist')(process.argv.slice(2))
if argv.h?
    console.log """
        -h view this help
        -x deployment target to backup
        -u username
        -p password
        -s subscription default:'system'
        -l loglevel (verbose, debug, info, warn)
    """
    return




getToken = () =>
    log.info 'Fetching Token', username:opts.username, password:opts.password, url:opts.url
    assert opts.username? or opts.password? or opts.url?, "Missing parameters"
    return new promise (fulfill, reject) =>
        rbody =
            identification: opts.username
            password: opts.password

        options =
            url: opts.url + "/token"
            method: 'POST'
            form: rbody
            headers:
                'Content-Type': "application/json"
        request options, (error,response, body) =>
            log.debug 'getToken: response to /token', error:error, body:body
            return reject error if error?
            opts.token = (JSON.parse body).token
            return fulfill opts

loadEntity = (options) =>
    return new promise (fulfill, reject) =>
        log.info 'loadEntity: Loading entities', options:options
        request options, (error, body, response) =>
            log.debug  'Response for load Entity', method:'loadEntity', error:error, response:response
            return reject error if error?
            return fulfill response

addDelay = (count) =>
    return new promise (fulfill, reject) =>
        resolve = =>
            return fulfill "succeess"
        setTimeout resolve, opts.delay * count


getServiceDomains = () =>
    return new promise (fulfill, reject) =>
        console.log "Making the call to backend"
        loadEntity  url:opts.url+"/serviceDomains", method:'GET', headers:{'Authorization': "Bearer #{opts.token}"}
        . then (resp) =>
            log.info "service domains", domains:(JSON.parse resp)
            opts.domains = (JSON.parse resp).serviceDomains
            console.log opts.domains
            return fulfill "success"
        , (error) =>
            return reject error

deleteServiceDomains = () =>
    actions = []
    log.info method:'Delete Domains', actions:actions
    count = 0
    for domain in opts.domains
        count++
        do (domain, count) =>
            deletecall = =>
                console.log "deleting domain with id #{domain.id}"
                loadEntity url:opts.url+"/serviceDomains/#{domain.id}", method: 'DELETE', headers:"Authorization":"Bearer #{opts.token}"
                . then (resp) =>
                    console.log "deleted domain with id #{domain.id}"
                , (error) =>
                    console.log "failed to delete domain with id #{domain.id}"


            console.log "sleeping by #{opts.delay * count} ms for domain #{domain.id}"
            setTimeout deletecall, (opts.delay * count)


opts =
    username: argv?.u ? 'username'
    password: argv?.p ? 'password'
    url:  argv?.x ? 'https://enterprise.dev.intercloud.net'
    accounts: argv?.a ? []
    subscription: argv?.s ? 'system'
    level: argv?.l ? 'info'
    delay: argv?.d ? 10000

log = new (require 'bunyan')
        name: 'account-stress'
        streams: [path: "/tmp/domains.log"]
        level: opts.level

console.log 'options passed in are ', opts
getToken()
. then (getServiceDomains)
. then (resp) =>
    deleteServiceDomains()
    console.log "success"
, (error) =>
    console.log "error ", error









