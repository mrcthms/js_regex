
# JsRegex

This is a Ruby gem that translates Ruby's regular expressions to the JavaScript flavor.

It has two advantages when compared to the most widespread approach
[[1]](https://dockyard.com/blog/ruby/2011/11/18/convert-ruby-regexp-to-javascript-regex)
[[2]](https://github.com/rails/rails/blob/b67043393b5ed6079989513299fe303ec3bc133b/actionpack/lib/action_dispatch/routing/inspector.rb#L42)
[[3]](https://github.com/DavyJonesLocker/client_side_validations/blob/4-2-stable/lib/client_side_validations/core_ext/regexp.rb#L3)
:

1. It [can handle far more](#SF) of Ruby's regex capabilities.
2. If any incompatibilities remain, it returns [helpful warnings](#HW) to indicate them.

This means you'll have better chances of translating your regexes, and if there is still a problem, at least you'll know.

### Installation

Add it to your gemfile or run

    gem install js_regex

### Usage

In Ruby:

```ruby
require 'js_regex'

ruby_hex_regex = /\h+/

js_regex = JsRegex.new(ruby_hex_regex)

js_regex.warnings # => []
js_regex.source # => '[a-fA-F0-9]+'
js_regex.options # => 'g'
```

If you want to inject the result directly into JavaScript, use *#to_s* or String interpolation. E.g. in inline JavaScript in HAML you can simply do:

```javascript
var regExp = #{js_regex};
```

If you want to convey the result via a DOM or JSON in order to feed it into the *new RegExp()* constructor in JavaScript, use *#to_h*. This also adds escapes required by the constructor.

In Ruby:

```ruby
js_regex = JsRegex.new(/\n{2}/)
js_regex.to_h # => {source: '\\n{2}', options: 'g'}
```

And then in JavaScript:

```javascript
var regExp = new RegExp(json_obj.source, json_obj.options);
```

<a name='HW'></a>
### Heed the Warnings

You might have noticed the empty *warnings* array in the example above:

```ruby
js_regex = JsRegex.new(ruby_hex_regex)
js_regex.warnings # => []
```

If this array isn't empty, that means that your Ruby regex contained some [stuff that can't be carried over to JavaScript](#UF). You can still use the result, but this is not recommended. Most likely it won't match the same strings as your Ruby regex.

```ruby
# this Ruby regex will match c-x
advanced_ruby_regex = /[a-x&&c-z]/

# the resulting JavaScript regex will match a-z
js_regex = JsRegex.new(advanced_ruby_regex)

js_regex.warnings # => ['Dropped unsupported character set intersection (&&) at index 5..6']
js_regex.source # => '[a-xc-z]'
```

<a name='SF'></a>
### Supported Features

In addition to the conversions supported by the default approach, this gem will correctly handle the following features:

| Description               | Example           |
|---------------------------|-------------------|
| escaped meta chars        | \\\A              |
| Ruby's multiline mode [4] | /.+/m             |
| Ruby's free-spacing mode  | / http (s?) /x    |
| atomic groups [5]         | a(?>bc&#124;b)c   |
| \h, \H, and \Z            | \h+\Z             |
| literal whitespace        | [a-z ]            |
| nested sets               | [a-z[A-Z]]        |
| types in sets             | [a-z\h]           |
| properties in sets        | [a-z\p{sc}]       |
| posix types               | [[:alpha:]]       |
| posix negations           | [[:^alpha:]]      |
| unicode bmp scripts       | \p{Arabic}        |
| unicode blocks            | \p{InBasicLatin1} |
| unicode categories [6]    | \p{Number}        |
| unicode properties [6]    | \p{Dash}          |
| unicode ages [6]          | \p{Age=5.2}       |
| unicode abbreviations [6] | \p{Mong}, \p{Sc}  |
| unicode negations [6]     | \p{^Number}       |

[4] Keep in mind that [Ruby's multiline mode](http://ruby-doc.org/core-2.1.1/Regexp.html#class-Regexp-label-Options) is totally different from [JavaScript's multiline mode](http://javascript.info/tutorial/ahchors-and-multiline-mode#multiline-mode).

[5] JavaScript doesn't support atomic groups, but JsRegex emulates their behavior by substituting them with [backreferenced lookahead groups](http://instanceof.me/post/52245507631/regex-emulate-atomic-grouping-with-lookahead).

[6] Some properties from these groups will result in very large JavaScript regexes.

<a name='UF'></a>
### Unsupported Features

Currently, the following functionalities can't be carried over to JavaScript. If you try to convert a regex that uses these features, corresponding parts of the pattern will be dropped from the result. In most of these cases that will lead to a warning, but changes that are not considered risky happen without warning. E.g. comments are removed silently because that won't lead to any operational differences between the Ruby and JavaScript regexes.

| Description                    | Example               | Warning |
|--------------------------------|-----------------------|---------|
| lookbehind                     | (?&lt;=, (?&lt;!, \K  | yes     |
| conditionals                   | (?(a)b&#124;c)        | yes     |
| group-specific options         | (?i:, (?-i:           | yes     |
| named capturing groups         | (?&lt;a&gt;, (?'a'    | no      |
| comment groups                 | (?#comment)           | no      |
| inline comments (in x-mode)    | /[a-z] # comment/x    | no      |
| set intersections              | [a-z&amp;&amp;[^uo]]  | yes     |
| recursive set negation         | [^a[^b]]              | yes     |
| possessive quantifiers         | ++, *+, ?+, {4,8}+    | yes     |
| multiplicative quantifiers [7] | A{4}{6}               | yes     |
| forward/backward references    | (\2two&#124;(one))+   | yes     |
| \k-backreferences              | (?'a'.)\k'a'\k'1'     | yes     |
| subexpression calls            | (?'a'.)\g'a'/, \G     | yes     |
| bell, escape, backspace chars  | \a, \e, [\b]          | yes     |
| wide hex, control, metacontrol | \x{1234}, \cD, \M-\C- | yes     |
| astral plane scripts [8]       | \p{Deseret}           | yes     |
| astral plane ranges            | [&#x1f601;-&#x1f632;] | yes     |
| matching astral chars with '.' | /./ =~ '&#x1f601;'    | no      |

[7] The given example would match 24 'A's. This is most likely just a bug in Ruby's regex engine, but JsRegex handles this case anyway to avoid SyntaxErrors in JavaScript.

[8] As of v2.2.2, Ruby itself only supports a small number of astral plane scripts.

### Performance

JsRegex is fairly fast. However, it does a lot more than the default approach, so it can take 2 to 20 times as long, depending on the complexity of the Ruby regex.

| Approach | total     | real      |
|----------|-----------|-----------|
| Default  | 0.069000  | 0.083174  |
| JsRegex  | 0.134000  | 0.142905  |

Seconds taken to convert a complicated 5-line expression 1000 times. [(benchmark code)](https://gist.github.com/janosch-x/554405a924f20d1d6db3)

### Contributions

Feel free to send suggestions, point out issues, or submit pull requests.

### Outlook

A few more of the unsupported features listed above could be implemented with some work. For instance, set intersection might be achieved by expanding set members and ranges, intersecting them manually, and then recompressing them into new ranges. Something similar could be done for certain group-specific options, e.g. case-insensitive groups could be substituted by alternations with case-swapped members. However, no amount of effort will lead to a full solution. Some regex behavior is simply impossible to achieve in JavaScript, and [litte seems to be happening](https://mail.mozilla.org/pipermail/es-discuss/2013-September/033867.html) that could change that.