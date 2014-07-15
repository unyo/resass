#!/usr/bin/env ruby

class ReSASS
    def initialize(glob)
        if (!glob)
            glob = "~/exm-client/core/css/*.scss"
        else
            glob = "#{glob}/*.scss"
        end
        puts "Processing #{glob}..."
        @files = Dir.glob(glob)
        @rulesets = []
        @current_ruleset = {}
        @pending_rulesets = []
        @browser_tags = ['-webkit-','-khtml-','-epub-','-moz-','-moz-osx-','-ms-','-o-']
        @order = [
            'position',
            'top',
            'right',
            'bottom',
            'left',
            'z-index',
            'display',
            'float',
            'width',
            'height',
            'max-width',
            'max-height',
            'min-width',
            'min-height',
            'padding',
            'padding-top',
            'padding-right',
            'padding-bottom',
            'padding-left',
            'margin',
            'margin-top',
            'margin-right',
            'margin-bottom',
            'margin-left',
            'margin-collapse',
            'margin-top-collapse',
            'margin-right-collapse',
            'margin-bottom-collapse',
            'margin-left-collapse',
            'overflow',
            'overflow-x',
            'overflow-y',
            'clip',
            'clear',
            'font',
            'font-family',
            'font-size',
            'font-smoothing',
            'osx-font-smoothing',
            'font-style',
            'font-weight',
            'hyphens',
            'src',
            'line-height',
            'letter-spacing',
            'word-spacing',
            'color',
            'text-align',
            'text-decoration',
            'text-indent',
            'text-overflow',
            'text-rendering',
            'text-size-adjust',
            'text-shadow',
            'text-transform',
            'word-break',
            'word-wrap',
            'white-space',
            'vertical-align',
            'list-style',
            'list-style-type',
            'list-style-position',
            'list-style-image',
            'pointer-events',
            'cursor',
            'background',
            'background-attachment',
            'background-color',
            'background-image',
            'background-position',
            'background-repeat',
            'background-size',
            'border',
            'border-collapse',
            'border-top',
            'border-right',
            'border-bottom',
            'border-left',
            'border-color',
            'border-image',
            'border-top-color',
            'border-right-color',
            'border-bottom-color',
            'border-left-color',
            'border-spacing',
            'border-style',
            'border-top-style',
            'border-right-style',
            'border-bottom-style',
            'border-left-style',
            'border-width',
            'border-top-width',
            'border-right-width',
            'border-bottom-width',
            'border-left-width',
            'border-radius',
            'border-top-right-radius',
            'border-bottom-right-radius',
            'border-bottom-left-radius',
            'border-top-left-radius',
            'border-radius-topright',
            'border-radius-bottomright',
            'border-radius-bottomleft',
            'border-radius-topleft',
            'content',
            'quotes',
            'outline',
            'outline-offset',
            'opacity',
            'filter',
            'visibility',
            'size',
            'zoom',
            'transform',
            'box-align',
            'box-flex',
            'box-orient',
            'box-pack',
            'box-shadow',
            'box-sizing',
            'table-layout',
            'animation',
            'animation-delay',
            'animation-duration',
            'animation-iteration-count',
            'animation-name',
            'animation-play-state',
            'animation-timing-function',
            'animation-fill-mode',
            'transition',
            'transition-delay',
            'transition-duration',
            'transition-property',
            'transition-timing-function',
            'background-clip',
            'backface-visibility',
            'resize',
            'appearance',
            'user-select',
            'interpolation-mode',
            'direction',
            'marks',
            'page',
            'set-link-source',
            'unicode-bidi',
            'speak',
            'tap-highlight-color'
        ]
    end
    def process_files!
        @files.each do |file|
            split_into_sass_rulesets!(file)
            check_rulesets!
        end
    end
    def start_new_ruleset!(ruleset_head, file)
        if @current_ruleset != {}
            @pending_rulesets.push(@current_ruleset)
        end
        @current_ruleset = {
            attribute: ruleset_head,
            declarations: [],
            file: file
        }
    end
    def end_ruleset!
        @rulesets.push(@current_ruleset)
        if (!@pending_rulesets.empty?)
            @current_ruleset = @pending_rulesets.pop
        else
            @current_ruleset = {}
        end
    end
    def unspecialize(name)
        @browser_tags.each do |tag|
            regex = Regexp.new("^#{tag}")
            name.gsub!(regex, '')
        end
        name
    end
    def add_new_declaration(declaration, i, line)
        name = unspecialize(declaration[1])
        order = @order.index(name)
        if (order.nil?)
            puts "Bad declaration #{i}: '#{name}', #{line}"
            order = -1
        end
        new_declaration = {
            declaration: name,
            name: declaration[1],
            value: declaration[2],
            index: i,
            order: order,
            line: line
        }
        @current_ruleset[:declarations].push(new_declaration)
    end
    def split_into_sass_rulesets!(current_file)
        # for each line in the file
        File.open(current_file).each_with_index do |line, i|
            # read from { to }
            if (ruleset_head = line.match(/(.*)\s*\{/))
                start_new_ruleset!(ruleset_head[1], current_file)
            elsif line[/\s*\}$/]
                end_ruleset!
            # ignore variables
            elsif line[/^\$\w+/]
                next
            elsif (declaration = line.match(/\s*([\w\-]+):\s*(.*);/))
                if !declaration or line[/\{/] or line[/\}/]
                    puts "Bad line #{i}"
                end
                add_new_declaration(declaration, i, line)
            # ignore newlines, comments, and includes
            elsif (line[/^\s*$/] or 
                (line[/^\s*\/\*/] and line[/\*\/\s*/]) or
                line[/^\s+\/\//] or
                line['@include'] or
                line['@import'] or
                line['@extend'] or
                line['@mixin'])
                next
            else 
                puts "Bad line #{current_file} [#{i}]:"
                puts "  #{line}"
            end
        end
    end
    def check_rulesets!
        @bad_rulesets = []
        @rulesets.each do |ruleset|
            last_declaration_order = 0
            ruleset_bad = false
            ruleset[:declarations].each do |declaration|
                if (last_declaration_order > declaration[:order])
                    #puts "File: #{ruleset[:file]}, Line: #{declaration[:index]}"
                    #puts "Bad order: '#{ruleset[:attribute]}' '#{declaration[:declaration]}' #{declaration[:index]}"
                    @bad_rulesets.push(ruleset)
                    ruleset_bad = true
                else
                    last_declaration_order = declaration[:order]
                end
            end
            if ruleset_bad
                ruleset[:declarations].sort! do |a, b|
                    a[:order] <=> b[:order]
                end
                puts "BAD ruleset #{ruleset[:file]} [#{(ruleset[:declarations].first[:index]-1)}]:"
                puts "#{ruleset[:attribute].strip} {"
                ruleset[:declarations].each do |declaration|
                    puts "  #{declaration[:name]}: #{declaration[:value]};"
                end
                puts "}"
            end
        end
    end
end

resass = ReSASS.new(ARGV.first)
resass.process_files!
