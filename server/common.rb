module LineCleaner
  def clean data
    @buffer ||= ""
    @buffer += data

    msgs = []

    while @buffer.length > 0
      next_close = @buffer.index "\x03"

      break if next_close.nil?

      next_piece = @buffer[1...next_close]

      msgs << next_piece

      @buffer = @buffer[(next_close + 1)..-1]
    end

    msgs
  end
end
