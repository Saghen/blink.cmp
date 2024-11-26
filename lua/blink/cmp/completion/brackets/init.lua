local brackets = {}

brackets.add_brackets = require('blink.cmp.completion.brackets.kind')
brackets.add_brackets_via_semantic_token = require('blink.cmp.completion.brackets.semantic')

return brackets
