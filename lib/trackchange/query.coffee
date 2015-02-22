page = require('webpage').create()
sys = require('system')

if (sys.args.length < 2 || sys.args.length > 3)
  console.log 'Usage: select.coffee URL [selector]'
  phantom.exit

address = sys.args[1]
selector = sys.args[2] || 'body'

query = (selector) ->
  nodeList = document.querySelectorAll(selector)
  nodeList.item(i).innerText for i in [0..nodeList.length-1]

storePageAndExit = ->
  result = page.evaluate query, selector
  console.log result.join("\n")
  phantom.exit()

page.open address, (status) ->
  if status != 'success'
    console.log 'Unable to load the address!'
    phantom.exit 1
  window.setTimeout storePageAndExit, 200
