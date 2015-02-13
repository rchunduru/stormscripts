needle = require 'needle'
fs = require 'fs'

argv = require('minimist')(process.argv.slice(2))
if argv.h?
    console.log """
        -h view this help
        -x deployment target
        -u username
        -p password
        -a account id
    """
    return



opts =
    username: argv?.u ? 'username'
    password: argv?.p ? 'password'
    url:  argv?.x ? 'https://enterprise-cpn.dev.intercloud.net'
    account: argv?.a ? "accountid"



needle.request  'POST', "#{opts.url}/token", {identification:opts.username, password:opts.password}, json:true, (error, resp) =>
    console.log "POST #{opts.url}/token #{resp?.statusCode}"
    if error or resp?.statusCode != 200
        return
    opts.token = resp?.body?.token
    console.log "token is ", opts.token, " for account ", opts.account, "headers is ", "Authorization:Bearer #{opts.token}"
    options =
        headers:
            "Authorization": "Bearer #{opts.token}"
    needle.get "#{opts.url}/accounts/#{opts.account}", options, (error, resp) =>
        console.log "GET #{opts.url}/accounts/#{opts.account} #{resp?.statusCode}"
        if error or resp?.statusCode != 200
            return
        opts.domainid = resp?.body?.account?.domain
        console.log "domain id is ", opts.domainid
        needle.get "#{opts.url}/serviceDomains/#{opts.domainid}", options, (error, resp) =>
            console.log "GET #{opts.url}/serviceDomains/#{opts.domainid} #{resp?.statusCode}"
            if error or resp?.statusCode != 200
                return
            opts.agentid = resp?.body?.serviceDomain?.agents[0]
            console.log "agent id is ", opts.agentid
            needle.get "#{opts.url}/serviceAgents/#{opts.agentid}", options, (error, resp) =>
                console.log "GET #{opts.url}/serviceAgents/#{opts.agentid} #{resp?.statusCode}"
                if error or resp?.statusCode != 200
                    return
                opts.serialKey = resp?.body?.serviceAgent?.serialKey
                opts.stoken = resp?.body?.serviceAgent?.stoken
                console.log "serial key is ", opts.serialKey
                console.log "stoken is ", opts.stoken
                metadata =
                    uuid : opts.serialKey
                    meta:
                        stormtracker:"https://#{opts.stoken}@stormtracker.dev.intercloud.net"
                fs.writeFileSync "/etc/meta-data.json", JSON.stringify(metadata)
                console.log "Created Metadata into /etc/meta-data.json"




