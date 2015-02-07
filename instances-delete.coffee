assert = require 'assert'
request = require 'request'
promise = require 'bluebird'
extend = require('util')._extend
fs = require 'fs'


argv = require('minimist')(process.argv.slice(2))
if argv.h?
    console.log """
        -h view this help
        -u username
        -p password
        -a  Auth URL
        -n  nova URL
        -t  Tenant Name
        -r  Region name
        -l loglevel (verbose, debug, info, warn)
    """
    return



opts =
    username: argv?.u ? 'username'
    password: argv?.p ? 'password'
    identity: argv?.a ? 'http://vhub3.dev.intercloud.net:5000/v2.0'
    compute: argv?.c ? 'http://vhub3.dev.intercloud.net:8774/v2/a17df6676fce4670a3872361b889d00a'
    level: argv?.l ? 'info'
    tenant: argv?.t ? 'cpn'
    region: argv?.r ? 'regionOne'

log = new (require 'bunyan')
        name: 'asset-stress'
        streams: [path: "/tmp/asset-stress.log"]
        level: opts.level
console.log 'options passed in are ', opts


getToken = () =>
    return new promise (fulfill, reject) =>
        roptions  =
            url: opts.identity + "/tokens"
            method: 'POST'
            #json: auth:identity:methods:["password"], password:user:name:opts.username, domain:{id:'default'}, password:opts.password
            json: auth:tenantName:opts.tenant, passwordCredentials:username:opts.username, password:opts.password
            headers:
                "Content-Type": "application/json"

        console.log 'roptions are ', roptions.json
        request roptions,  (error, body, response) =>
            log.debug  'Response for load Entity', method:'getToken', error:error, response:response
            console.log 'token response', response
            return reject error if error? or response.error?
            return fulfill response.access.token.id

deleteInstance = (instance, token) =>
    request url:opts.compute  + "/servers/#{instance}", method:'DELETE', headers: 'X-Auth-Token': token,  (error, body, response) =>
        log.debug 'response for delete instance ', method:'deleteInstance', error:error, response:response
        return error if error
        console.log "deleted the instance ", instance
        return "success"


getInstances = () =>
    return new promise (fulfill, reject) =>
        getToken()
        . then (token) =>
            log.info "token created ", resp:token
            console.log 'token using ', token
            request url:opts.compute + "/servers", method: 'GET', headers:{ 'x-auth-token':token}, (error, body, response) =>
                log.debug  'Response for get Instances ', method:'getInstances', error:error, response:response
                return reject error if error?
                servers = (JSON.parse response).servers
                instances = []
                actions = []
                instances.push server.id for server in servers
                log.debug 'instances are ', method:'getInstances', instances:instances
                instances.map (instance) =>
                    actions.push (deleteInstance instance, token)
                promise.all(instances)
                . then (resp) =>
                    return fulfill "success"
                , (error) =>
                    return reject error

        , (error) =>
            log.error "failed to get instances ", error:error
            return reject error

        





getInstances()
. then (resp) =>
    console.log resp
, (error) =>
    console.log error







