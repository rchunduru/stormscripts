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
        -i imageid
        -f flavorid
        -identity Auth URL
        -endpoint EndpointURL
        -neutron  network URL
        -compute  nova URL
        -glance   glance URL
        -tenant   Tenant Name
        -region   Region name
        -limit    Number of assets to create
        -l loglevel (verbose, debug, info, warn)
    """
    return




loadEntity = (options) =>
    return new promise (fulfill, reject) =>
        log.info 'loadEntity: Loading entities', method:options.method, form:options.form, url:options.url, headers: options.headers
        roptions  =
            url: options.url
            method: 'POST'
            json:  options.form
            headers:
                "Content-Type": "application/json"

        console.log 'roptions are ', roptions
        request roptions,  (error, body, response) =>
            log.debug  'Response for load Entity', method:'loadEntity', error:error, response:response
            return reject error if error?
            return fulfill response

createAsset = (asset) =>
    return new promise (fulfill, reject) =>
        loadEntity url:opts.url+"/createAsset", method: 'POST', form: asset, headers:{'Content-Type':"application/json"}
        . then (resp) =>
            log.info "asset created ", resp:resp
            return fulfill "success"
        , (error) =>
            log.error "failed to create asset ", error:error
            return reject error

createAssets = () =>
    return new promise (fulfill, reject) =>
        actions = []
        opts.assets.map (asset) =>
            actions.push(createAsset asset)

        log.info method:'createAssets', actions:actions
        promise.all(opts.assets)
        . then (resp) =>
            return fulfill "success"
        , (error) =>
            return reject error

createList = () =>
    return new promise (fulfill, reject) =>
        opts.assets = []
        count = 0
        while count isnt opts.limit
            asset =
                hostName: "auto-generated-#{count}"
                resourceId: "auto-generated-#{count}"
                assetProvider:
                    username: opts.username
                    password: opts.password
                    endPoint: opts.endpoint
                    tenant:   opts.tenant
                    regionName: opts.region
                    neutron: opts.neutron
                    image:  opts.image
                    compute: opts.compute
                    identity: opts.identity
                remediation: false
                assetModel:
                    name: "auto generated model"
                    flavor: opts.flavor
                    image: opts.imageid
                stormTokenId: "someToken"
                controlProvider:
                    stormtrackerURL: opts.stormtrackerURL
                    stormkeeperURL: opts.stormkeeperURL
                    stormlightURL: opts.stormlightURL
                    defaultDomainId: count
                    bolt:
                        uplinks: opts.boltUplinks
                        uplinkStrategy: "round-robin"
                agentId: "auto-generated-#{count}"
                notify:
                    Url: opts.notifyUrl
                    token: opts.token

            opts.assets.push asset
            count++
        return fulfill "success"
        

opts =
    username: argv?.u ? 'username'
    password: argv?.p ? 'password'
    url:      argv?.url ? "http://localhost:9080/StormIO"
    endpoint:  argv?.x ? 'http://vhub3.dev.intercloud.net:5000/v2.0'
    imageid:  argv?.i ? 'unknown'
    flavor:   argv?.f ? '1'
    identity: argv?.identity ? 'http://vhub3.dev.intercloud.net:5000/v2.0'
    neutron: argv?.neutron ? 'http://vhub3.dev.intercloud.net:9696'
    compute: argv?.compute ? 'http://vhub3.dev.intercloud.net:8774/v2/a17df6676fce4670a3872361b889d00a'
    image: argv?.glance ? 'http://vhub3.dev.intercloud.net:9292/v2'
    level: argv?.l ? 'info'
    tenant: argv?.tenant ? 'cpn'
    region: argv?.region ? 'regionOne'
    limit: argv?.limit ? 48
    stormtrackerURL:  argv?.stormtracker ? "https://stormtracker.dev.intercloud.net"
    stormkeeperURL:  argv?.stormkeeper ? "http://stormtkeeper"
    stormlightURL :  argv?.stormlight ? "http://stormtlight"
    notifyUrl: argv?.notify ? "http://localhost:8080"
    token:  argv?.token ? 'sampletoken'

log = new (require 'bunyan')
        name: 'asset-stress'
        streams: [path: "/tmp/asset-stress.log"]
        level: opts.level
console.log 'options passed in are ', opts





createList()
. then (createAssets)
. then (resp) =>
    console.log "success"
, (error) =>
    console.log "error ", error









