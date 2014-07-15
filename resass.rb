#!/usr/bin/env ruby

class ReSASS
    def initialize(glob)
        if (!glob)
            glob = './exm-client/core/css/*.scss'
        end
        @files = Dir.glob(glob)
        @chunks = []
        @current_chunk = {}
        @pending_chunks = []
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
            split_into_sass_chunks!(file)
            check_chunks!
            display_correct_chunks!
        end
    end
    def start_new_chunk!(chunk_head, file)
        if @current_chunk != {}
            @pending_chunks.push(@current_chunk)
        end
        @current_chunk = {
            attribute: chunk_head,
            properties: [],
            file: file
        }
    end
    def end_chunk!
        @chunks.push(@current_chunk)
        if (!@pending_chunks.empty?)
            @current_chunk = @pending_chunks.pop
        else
            @current_chunk = {}
        end
    end
    def unspecialize(name)
        @browser_tags.each do |tag|
            regex = Regexp.new("^#{tag}")
            name.gsub!(regex, '')
        end
        name
    end
    def add_new_property(property, i, line)
        name = unspecialize(property[1])
        order = @order.index(name)
        if (order.nil?)
            puts "Bad property #{i}: '#{name}', #{line}"
            order = -1
        end
        new_property = {
            property: name,
            name: property[1],
            value: property[2],
            index: i,
            order: order,
            line: line
        }
        @current_chunk[:properties].push(new_property)
    end
    def split_into_sass_chunks!(current_file)
        # for each line in the file
        File.open(current_file).each_with_index do |line, i|
            # read from { to }
            if (chunk_head = line.match(/(.*) \{/))
                start_new_chunk!(chunk_head[1], current_file)
            elsif line[/\s*\}$/]
                end_chunk!
            # ignore variables
            elsif line[/^\$\w+/]
                next
            elsif (property = line.match(/\s*([\w\-]+): (.*);/))
                if !property or line[/\{/] or line[/\}/]
                    puts "Bad line #{i}"
                end
                add_new_property(property, i, line)
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
                puts "Bad line #{i}: #{line}"
            end
        end
    end
    def check_chunks!
        @bad_chunks = []
        @chunks.each do |chunk|
            last_property_order = 0
            chunk_bad = false
            chunk[:properties].each do |property|
                if (last_property_order > property[:order])
                    puts "File: #{chunk[:file]}, Line: #{property[:index]}"
                    puts "Bad order: '#{chunk[:attribute]}' '#{property[:property]}' #{property[:index]}"
                    @bad_chunks.push(chunk)
                    chunk_bad = true
                else
                    last_property_order = property[:order]
                end
            end
            if chunk_bad
                chunk[:properties].sort! do |a, b|
                    a[:order] <=> b[:order]
                end
                puts "BAD CHUNK, #{chunk[:file]}:"
                puts "#{chunk[:attribute]} {"
                chunk[:properties].each do |property|
                    puts "  #{property[:name]}: #{property[:value]};"
                end
                puts "}"
            end
        end
    end
    def display_correct_chunks!
        @bad_chunks.each do |chunk|
        end
    end
end

resass = ReSASS.new(ARGV.first)
resass.process_files!