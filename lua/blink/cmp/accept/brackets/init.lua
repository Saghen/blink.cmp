local brackets = {}

brackets.add_brackets = require('blink.cmp.accept.brackets.kind')
brackets.add_brackets_via_semantic_token = require('blink.cmp.accept.brackets.semantic')

return brackets
