defmodule Innerpeace.Db.Utilities.CardNoGenerator do
  @moduledoc """
  """

  alias Innerpeace.Db.Base.PayorCardBinContext

  # Generate card number
  def generate_card_number(payor_id) do
    payor_id
    |> get_and_increment_sequence_number
    |> generate_card_number_base
    |> generate_card_number_mod_10
  end

  # Get and increment sequence number
  def get_and_increment_sequence_number(payor_id) do
    payor_card_bin = PayorCardBinContext.get_payor_card_bin_by_payor_id(
      payor_id)

    if is_nil(payor_card_bin) do
      {:error, "Payor card bin not registered"}
    else
      PayorCardBinContext.update_payor_card_bin(
        payor_card_bin.id,
        %{sequence: (payor_card_bin.sequence + 1)})

        payor_card_bin
    end

  end

  # Generate 15-digit Card Number Base
  def generate_card_number_base(payor_card_bin) do

    case payor_card_bin do
      {:error, "Payor card bin not registered"} ->
        {:error, "Payor card bin not registered"}
      _ ->
        if String.length(payor_card_bin.card_bin) == 8 do
          card_no = payor_card_bin.sequence
                    |> Integer.to_string
                    |> String.pad_leading(7, "0")

                    "#{payor_card_bin.card_bin}#{card_no}"
        else
          {:error, "Invalid card bin length"}
        end
    end

  end

  # Generate card number mod 10
  def generate_card_number_mod_10(card_number_base) do

    case card_number_base do
      {:error, "Payor card bin not registered"} ->
        {:error, "Payor card bin not registered"}
      {:error, "Invalid card bin length"} ->
        {:error, "Invalid card bin length"}
      _ ->
        if String.length(card_number_base) == 15 do
          card_sum = card_number_sum(Enum.reverse(String.graphemes(
            card_number_base)), 0)
            card_no_last_digit =
              rem(((div(card_sum, 10) + 1) * 10 - card_sum), 10)

            "#{card_number_base}#{card_no_last_digit}"
        else
          {:error, "Invalid card number base length"}
        end
    end

  end

  def card_number_sum([], card_sum), do: card_sum
  def card_number_sum([digit | card_number], card_sum) do
    card_number_temp = Enum.join(Enum.reverse(card_number), "")

    card_sum =
      if rem(String.length(card_number_temp), 2) == 0 do
        card_sum + sum_number(String.graphemes(
          Integer.to_string(String.to_integer(digit) * 2)))
      else
        card_sum + String.to_integer(digit)
      end

    card_number_sum(card_number, card_sum)
  end

  def sum_number([]), do: 0
  def sum_number([digit | number]), do: String.to_integer(digit) + sum_number(number)
end
