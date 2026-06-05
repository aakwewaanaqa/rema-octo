module Processor 
  def chomp_comment file_text
    file_text.split("\n").map do |line|
      not_comment_part = line.split('#')[0]
      not_comment_part = not_comment_part.rstrip unless not_comment_part.nil? 
      
      not_comment_part
    end.join("\n")
  end
end