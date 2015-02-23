page = require('webpage').create()
sys = require('system')

if (sys.args.length < 2 || sys.args.length > 3)
  console.log 'Usage: query.coffee URL [selector]'
  phantom.exit 1

address = sys.args[1]
selector = sys.args[2] || 'body'

# this will be evaluated within the context of the page
query = (selector) ->
  nodeList = document.querySelectorAll(selector)
  result = ['(Empty selection.)'] if nodeList.length == 0
  result ||= (nodeList.item(i).innerText for i in [0..nodeList.length-1])

queryPageAndExit = ->
  result = page.evaluate query, selector
  console.log result.join("\n")
  phantom.exit()

page.open address, (status) ->
  if status != 'success'
    console.log "Unable to load page #{address}"
    phantom.exit 2
  window.setTimeout queryPageAndExit, 500
