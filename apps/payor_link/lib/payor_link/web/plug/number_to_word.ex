defmodule Innerpeace.PayorLink.NumberToWord do
  @moduledoc """
  Functions to convert number to words.
  """

  @spec say(integer) :: String.t
  def say(n), do: n |> say_io() |> IO.iodata_to_binary()

  @spec say_io(integer) :: iodata
  def say_io(0), do: ""
  def say_io(1), do: "one"
  def say_io(2), do: "two"
  def say_io(3), do: "three"
  def say_io(4), do: "four"
  def say_io(5), do: "five"
  def say_io(6), do: "six"
  def say_io(7), do: "seven"
  def say_io(8), do: "eight"
  def say_io(9), do: "nine"
  def say_io(10), do: "ten"
  def say_io(11), do: "eleven"
  def say_io(12), do: "twelve"
  def say_io(13), do: "thirteen"
  def say_io(14), do: "fourteen"
  def say_io(15), do: "fifteen"
  def say_io(16), do: "sixteen"
  def say_io(17), do: "seventeen"
  def say_io(18), do: "eighteen"
  def say_io(19), do: "nineteen"
  def say_io(20), do: "twenty"
  def say_io(30), do: "thirty"
  def say_io(40), do: "forty"
  def say_io(50), do: "fifty"
  def say_io(60), do: "sixty"
  def say_io(70), do: "seventy"
  def say_io(80), do: "eighty"
  def say_io(90), do: "ninety"
  def say_io(n) when n < 100 do
    tens = div(n, 10) * 10
    remainder = rem(n, 10)
    format(tens, "", " ", remainder)
  end
  def say_io(n) when n < 1000 do
    hundreds = div(n, 100)
    remainder = rem(n, 100)
    format(hundreds, " hundred", separator(remainder), remainder)
  end
  ~w[thousand million billion trillion quadrillion quintillion sextillion septillion octillion nonillion decillion]
  |> Enum.zip(Stream.unfold(1000, fn acc -> {acc, acc * 1000} end))
  |> Enum.each(fn {suffix, m} ->
    def say_io(n) when n < (unquote(m) * 1000) do
      number = div(n, unquote(m))
      remainder = rem(n, unquote(m))
      format(number, " " <> unquote(suffix), separator(remainder), remainder)
    end
  end)

  @spec separator(integer) :: String.t
  def separator(remainder) when remainder < 100, do: " and "
  def separator(_remainder), do: ", "

  @spec format(integer, String.t, String.t, integer) :: iodata
  def format(number, illion, _separator, 0), do: [say_io(number) | illion]
  def format(number, illion, separator, remainder), do: [say_io(number), illion, separator | say_io(remainder)]
end
