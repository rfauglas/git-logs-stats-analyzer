require "git/stats/maker/version"
require 'csv'

module Git
  module Stats
    module Maker
      out = `cd #{$ARGV[0]}]}; git log --date=format:'%Y-%m-%d %H:%M:%S' --shortstat`

      commits = []
      revertedCommits= Set.new

      splitCommits = out.split(/^commit /m)
      splitCommits.shift
      splitCommits.each do |token|
        ary = token.scan (/([^\n]*)\nAuthor: ([^\n]*)\nDate:   ([^\n]*)\n(.*)/m) do |commitId,author,date,comment|
          if (comment =~ /This reverts commit (.*)\.\n/m)
            revertedCommits << $1
            puts "Reverted: #{comment}"
            next
          end
          if (comment =~ /(.*)\n (\d+) files? changed(, (\d+) insertions?\(\+\))?(, (\d+) deletions?\(-\))?\n/m)
            commits<< {:commitId => commitId,
                       :author=> author,
                       :date => date,
                       :changedFiles=>$2,
                       :newLines=> $4,
                       :suppressLines=> $6 ,
                       :comment =>  $1
                                        .gsub(/^$\n/,'')
                                        .chomp('\n')
            }
          else
            puts "Not matched: #{comment}"
          end
        end
      end


      commits.select! { |commit | !revertedCommits.include?(commit[:commitId]) }

      CSV::open("file.csv", "wb") do |csv|
        csv << ["commit", "author", "date", "comment", "changed files", "new lines","line suppressed"]
        commits.each do |commit|
          csv << [commit[:commitId], commit[:author], commit[:date], commit[:comment], commit[:changedFiles], commit[:newLines],commit[:suppressLines]];
        end
      end
    end
  end
end