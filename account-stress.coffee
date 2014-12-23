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
        log.info 'loadEntity: Loading entities', options:options, body:options.form.owner
        request options, (error, body, response) =>
            log.debug  'Response for load Entity', method:'loadEntity', error:error, response:response
            return reject error if error?
            return fulfill response

createAccount = (account) =>
    return new promise (fulfill, reject) =>
        loadEntity url:opts.url+"/accounts", method: 'POST', headers:{'content-type':"application/json", 'Authorization':"Bearer #{opts.token}"}, form:account:{name:account, subscription:opts.subscription, owner:firstName:account, lastName:account, email:"#{account}@intercloud.net"}
        . then (resp) =>
            log.info "account created ", resp:resp
            return fulfill "success"
        , (error) =>
            log.error "failed to create account", error:error
            return reject error

createAccounts = () =>
    return new promise (fulfill, reject) =>
        actions = []
        opts.accounts.map (account) =>
            actions.push(createAccount  account)

        log.info method:'createAccounts', actions:actions
        promise.all(opts.accounts)
        . then (resp) =>
            return fulfill "success"
        , (error) =>
            return reject error

opts =
    username: argv?.u ? 'username'
    password: argv?.p ? 'password'
    url:  argv?.x ? 'https://enterprise.dev.intercloud.net'
    accounts: argv?.a ? []
    subscription: argv?.s ? 'system'
    level: argv?.l ? 'info'

log = new (require 'bunyan')
        name: 'account-stress'
        streams: [path: "/tmp/account-stress.log"]
        level: opts.level
console.log 'options passed in are ', opts
getToken()
. then (createAccounts)
. then (resp) =>
    console.log "success"
, (error) =>
    console.log "error ", error









