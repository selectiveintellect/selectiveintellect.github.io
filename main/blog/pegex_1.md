# Parsing Files Using Perl's Pegex Module

[Pegex](https://metacpan.org/pod/Pegex) is an interesting module for parsing
text data. Instead of using regular expressions directly, the user can write a
grammar for the data to be parsed and have the data be automatically converted
to a native Perl object or if the user desires use actions to handle the grammar
while parsing using a
[Pegex::Receiver](https://metacpan.org/pod/distribution/Pegex/lib/Pegex/Receiver.pod)
class.

`Pegex` uses the type of grammars called [Parsing Expression Grammars
(PEG)](https://en.wikipedia.org/wiki/Parsing_expression_grammar), which is an
**unambiguous** form of writing a grammar. Each parsed string will in effect
have a single valid parse tree. Since `Pegex` converts the rules of the grammar to
regular expressions, it is a greedy parser.

In this blog post we demonstrate how to easily use Pegex to parse an
`/etc/hosts` file on Linux and convert the result into Perl objects
automatically **without** having to manually create any object.

## The `/etc/hosts` file

Let's take a look at a typical `/etc/hosts` file on a Linux system. The below
file has some manually entered entries for `router` and `ubuntuserver` in
addition to the default entries for the `localhost` which is named `debian`.

We want to parse this file using `Pegex` and convert each line into a native
Perl hash with the appropriate keys defining whether the address is IPv4 or IPv6
and what the host names are and their respective IP addresses. We can do this
without using any `split` functions or manually writing any regular expressions !


    127.0.0.1	localhost
    127.0.1.1	debian.example.local	debian
    192.168.1.1 router 
    192.168.1.3 ubuntuserver
    # this is a comment and below is a blank line

    # The following lines are desirable for IPv6 capable hosts
    ::1     ip6-localhost ip6-loopback
    fe00::0 ip6-localnet
    ff00::0 ip6-mcastprefix
    ff02::1 ip6-allnodes
    ff02::2 ip6-allrouters


## Writing the Grammar

The `Pegex` grammar has its own syntax as described in
[Pegex::Syntax](https://metacpan.org/pod/distribution/Pegex/lib/Pegex/Syntax.pod).

The grammar is a collection of rules and looks like below:


    %grammar etchosts
    %version 0.01

    hosts: host | blanks | comments
    comments: /- HASH ANY* EOL/
    blanks: /- EOL/
    host: ip - names /- EOL?/
    ip: ipv4 | ipv6
    names: name+
    name: - /((: WORD | DOT | DASH )+)/ -

    ipv4: /((: DIGIT{1,3} DOT ){3} DIGIT{1,3} )/
    ipv6: /((: HEX* COLON{1,2} HEX* )+ )/


The lines beginning with the `%` tag are meta rules and represent information on
the grammar such as the name of the grammar and the version. This allows the
developer to manage multiple versioned grammars in their program. 

The rest of the lines are rules and they begin with a rule name and a `:`
followed by the description of the rule as per the `Pegex::Syntax` document.

The first rule `hosts` is the global or top-level rule for the grammar. The
`hosts` rule can have three variations, viz., `host`, `blanks` and `comments`
which represent the host definitions, blank lines and comments beginning with
`#`, respectively. We need to be able to handle blank lines and comments since
various `/etc/hosts` files have them either by default or added by the user.


The `-` is a shorthand for whitespace and `EOL` is a shorthand for the end of line
characters `\r\n` or `\n`. `HASH` is a named rule describing the `#` symbol and
`COLON` is a named rule describing the `:` symbo. `DIGIT` represents the regular
expression `[0-9]`, `HEX` represents the regular expression `[0-9A-Fa-f]` that
describes numbers in the hexadecimal format, and `ANY` represents any character
except newline. The `WORD` represents the regular expression `\w`, `DOT` and
`DASH` represent the `.` and `-` characters, respectively.

Detailed descriptions of all the available shorthands or _atoms_ are available at
[Pegex::Grammar::Atoms](https://raw.githubusercontent.com/ingydotnet/pegex-pm/master/lib/Pegex/Grammar/Atoms.pm)

Rules enclosed in `//` define a specific regular expression that will be
generated, and are useful for creating the low-level rules using the _atoms_.

High-level rules are a collection of other rules separated using the `|` (OR)
operation or the default AND operation. 

## Executing the Grammar

The grammar can be then placed in a string using the heredoc format in Perl or
by reading it from a file or loading it from a database or any other method as
required by the developer. The beauty of using `Pegex` to parse arbitrary files
is that the grammars can be loaded on the fly and used for parsing, without
having to edit the overall script.

`Pegex` parses text files one line at a time. The parsing is _stateless_, so to
maintain state the user will need to develop a [Pegex::Receiver]() class. If the
file is a collection of stateless lines such as `/etc/hosts` is we can use the
in-built receiver class and retrieve an object for each line using the `pegex()`
function directly as shown in the below script.

We collect the parsed objects and dump them as a YAML string using the `YYY`
function from the `XXX` module which is a great debugging tool. The user can use
`Data::Dumper` to dump the objects in the Perl format.

Below is what the final script looks like, and it can be downloaded
as [etchosts.pl here](here).

<pre><code class="perl">
#!/usr/bin/env perl
use strict; 
use warnings;
use 5.10.0;
use feature 'say';
use Pegex;
use Data::Dumper;

my $grammar = &lt;&lt;EOF;
%grammar etchosts
%version 0.01

hosts: host | blanks | comments
comments: /- HASH ANY* EOL/
blanks: /- EOL/
host: ip - names /- EOL?/
ip: ipv4 | ipv6
names: name+
name: - /((: WORD | DOT | DASH )+)/ -

ipv4: /((: DIGIT{1,3} DOT ){3} DIGIT{1,3} )/
ipv6: /((: HEX* COLON{1,2} HEX* )+ )/

EOF

my @rows = ();
while (&lt;&gt;) {
    push @rows, pegex($grammar)-&gt;parse($_);
}
$Data::Dumper::Indent = 0;
say Dumper(\@rows);

</code></pre>

The sample `/etc/hosts` file shown above can be downloaded as [etchosts_sample here]().

We now run the following command and view the output in YAML:

<pre><code class="bash">

$ perl etchosts.pl etchosts_sample

</code></pre>
<pre><code class="yaml">
---
- hosts:
    host:
      - ip:
          ipv4: 127.0.0.1
      - names:
          - name:
              - localhost
- hosts:
    host:
      - ip:
          ipv4: 127.0.1.1
      - names:
          - name:
              - debian.selectiveintellect.local
          - name:
              - debian
- hosts:
    host:
      - ip:
          ipv4: 192.168.1.1
      - names:
          - name:
              - router
- hosts:
    host:
      - ip:
          ipv4: 192.168.1.3
      - names:
          - name:
              - ubuntuserver
- hosts: []
- hosts: []
- hosts:
    host:
      - ip:
          ipv6: ::1
      - names:
          - name:
              - ip6-localhost
          - name:
              - ip6-loopback
- hosts:
    host:
      - ip:
          ipv6: fe00::0
      - names:
          - name:
              - ip6-localnet
- hosts:
    host:
      - ip:
          ipv6: ff00::0
      - names:
          - name:
              - ip6-mcastprefix
- hosts:
    host:
      - ip:
          ipv6: ff02::1
      - names:
          - name:
              - ip6-allnodes
- hosts:
    host:
      - ip:
          ipv6: ff02::2
      - names:
          - name:
              - ip6-allrouters
...
</code></pre>
