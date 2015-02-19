page = require('webpage').create()
sys = require('system')

if (sys.args.length < 2 || sys.args.length > 3)
  console.log 'Usage: select.coffee URL [selector]'
  phantom.exit

address = sys.args[1]
selector = sys.args[2] || 'body'

query = (selector) ->
  document.querySelector(selector).innerText

storePageAndExit = ->
  result = page.evaluate query, selector
  console.log result
  phantom.exit()

page.open address, (status) ->
  if status != 'success'
    console.log 'Unable to load the address!'
    phantom.exit 1
  window.setTimeout storePageAndExit, 200
