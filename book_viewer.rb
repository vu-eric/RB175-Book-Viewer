require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"

helpers do 
  def in_paragraphs(str)
    str.split("\n\n").map.with_index do |line, index|
      "<p id=#{index}>" + line + "</p>"
    end.join
  end

  def highlight(text, term)
    text.gsub(term, %(<strong>#{term}</strong>))
  end

  def each_chapter
    @contents.each_with_index do |name, index|
      number = index + 1
      contents = File.read("data/chp#{number}.txt")
      yield number, name, contents
    end
  end

  def chapters_matching(query)
    results = []

    return results if !query || query.empty?

    each_chapter do |number, name, contents|
      results << {number: number, name: name}.merge( paragraphs_matching(contents, query)) if contents.include?(query)
    end
    results
  end

  def paragraphs_matching(contents, query)
     results = []
     contents.split("\n\n").each_with_index do |line, index|
        results << {text: line, id: index} if line.include?(query)
     end 
     {paras: results}
  end
end

before do
  @contents = File.readlines("data/toc.txt")
end

get "/" do
  @title = "The Adventures of Sherlock Holmes"

  erb :home
end

get "/chapters/:num" do
  chapter_num = params[:num].to_i

  redirect "/" unless (1..@contents.size).cover? chapter_num

  @title = "Chapter #{chapter_num}: #{@contents[chapter_num - 1]}"
  @chapter = File.read("data/chp#{chapter_num}.txt")

  erb :chapter
end

get "/search" do
  @results = chapters_matching(params[:query])
  erb :search
end

not_found do 
  redirect "/"
end

