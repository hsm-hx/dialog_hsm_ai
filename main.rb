require './marcov.rb'
require './topic.rb'

def main()
  n = NattoParser.new

  str = STDIN.gets
  keyword = n.extractWord(str)

=begin 
  # ソースを指定して読み込み
  if(ARGV[0] and ARGV[1]) != nil
    dir = "data/" << ARGV[0] << "_" << ARGV[1] << ".json"
  else
    dir = ""
  end
=end

  # 会話文を生成
  sentence = generate_text_from_json(keyword, "")

  p sentence
end

main()
