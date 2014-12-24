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

addDelay = () =>
    return new promise (fulfill, reject) =>
        resolve = =>
            return fulfill "succeess"
        setTimeout resolve, opts.delay


getAccounts = () =>
    return new promise (fulfill, reject) =>
        loadEntity  url:opts.url+"/accounts", method:'GET', headers:{'Authorization': "Bearer #{opts.token}"}
        . then (resp) =>
            log.info "accounts list", accounts:(JSON.parse resp)
            opts.accounts = (JSON.parse resp).accounts
            return reject new Error "no accounts found" if opts.accounts.length is 0
            console.log opts.accounts
            return fulfill "success"
        , (error) =>
            return reject error

deleteAccount = (account) =>
    return new promise (fulfill, reject) =>
        console.log "Deleting Account with id #{account.name}"
        loadEntity url:opts.url+"/accounts/#{account.id}", method: 'DELETE', headers:"Authorization":"Bearer #{opts.token}"
        . then (resp) =>
            log.info "account deleted", resp:resp
            addDelay()
            . then (resp) =>
                return fulfill "success"
        , (error) =>
            log.error "failed to delete account", error:error
            return reject error

deleteAccounts = () =>
    return new promise (fulfill, reject) =>

        log.info method:'Delete Accounts'
        opts.accounts.filter (account) =>
            addDelay()
            . then (resp) =>
                switch account.id
                    when 'ht-provider', 'dt-provider', 'cpn-provider'
                        console.log "skipping account with name #{account.name}"
                        return
                    else
                        console.log "Deleting account with id #{account.id}"
                        deleteAccount account
                        return


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
        streams: [path: "/tmp/accounts.log"]
        level: opts.level

console.log 'options passed in are ', opts
getToken()
. then (getAccounts)
. then (deleteAccounts)
. then (resp) =>
    console.log "success"
, (error) =>
    console.log "error ", error









