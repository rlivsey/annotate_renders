# Copyright (c) 2006 Richard Livsey
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module ActionView #:nodoc:
  module Annotated #:nodoc:
      
      def self.included(base) # :nodoc:
        base.class_eval do 
          alias_method :old_render_file, :render_file
          alias_method :render_file, :annotated_render_file
        end
      end

      def annotated_render_file(template_path, use_full_path = true, local_assigns = {}) #:nodoc:       
                
        return old_render_file(template_path, use_full_path, local_assigns) unless logger && logger.debug?

        rendered = nil
        
        require 'benchmark'
        benchmark = Benchmark.measure {
          rendered = old_render_file(template_path, use_full_path, local_assigns)
        } 

        if use_full_path
          template_path_without_extension, template_extension = path_and_extension(template_path)

          if template_extension
            template_file_name = full_template_path(template_path_without_extension, template_extension)
          else
            template_extension = pick_template_extension(template_path).to_s
            template_file_name = full_template_path(template_path, template_extension)
          end
        else
          template_file_name = template_path
          template_extension = template_path.split('.').last
        end
        
        return rendered unless template_extension == 'rhtml'

        abs_template_file_name = File.expand_path(template_file_name)
        rails_root_length =  File.expand_path(RAILS_ROOT).length
        rel_template_file_name = abs_template_file_name[rails_root_length, abs_template_file_name.length]

        if template_path.include?('layouts')
          "#{rendered}<!-- LAYOUT END (start was suppressed) (#{rel_template_file_name}) time (real): #{benchmark.real}-->"
        else
          "<!-- BEGIN (#{rel_template_file_name}) -->#{rendered}<!-- END (#{rel_template_file_name}) time (real): #{benchmark.real}-->"
        end

      end
  end
end

ActionView::Base.send :include, ActionView::Annotated
