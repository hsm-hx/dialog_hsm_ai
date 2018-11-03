require './marcov.rb'

def main()
  if ARGV[0] != nil
    keyword = ARGV[0]
  else
    keyword = -1
  end

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
