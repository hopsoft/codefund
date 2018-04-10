defmodule CodeFundWeb.SponsorshipType do
  use CodeFundWeb.BaseType
  alias CodeFund.Schema.Sponsorship
  alias CodeFund.Schema.User
  import Ecto.Query

  def build_form(form) do
    form
    |> add(
      :campaign_id,
      SelectAssoc,
      label: "Campaign",
      validation: [:required],
      choices: object_query_for_user("Campaign", form.struct.user)
    )
    |> add(:property_id, SelectAssoc, label: "Property", validation: [:required])
    |> add(
      :creative_id,
      SelectAssoc,
      label: "Creative",
      validation: [:required],
      choices: object_query_for_user("Creative", form.struct.user)
    )
    |> add(
      :bid_amount,
      :number_input,
      label: "CPC",
      validation: [:required],
      addon: "$",
      phoenix_opts: [
        step: "0.01",
        min: "0"
      ]
    )
    |> add(
      :redirect_url,
      :text_input,
      label: "URL",
      validation: [
        :required,
        format: [arg: ~r/^https?:\/\/.+$/]
      ]
    )
    |> add(
      :override_revenue_rate,
      override_field_type(form.struct.current_user),
      label: override_field_label(form.struct.current_user),
      validation: [:required],
      phoenix_opts: [
        value: set_overrate_revenue_rate_default(form.struct),
        step: "0.001",
        min: "0"
      ]
    )
    |> add(
      :save,
      :submit,
      label: "Submit",
      phoenix_opts: [
        class: "btn-primary"
      ]
    )
  end

  defp object_query_for_user(type, %User{id: id}) do
    from(o in Module.concat([CodeFund, Schema, type]), where: o.user_id == ^id)
    |> CodeFund.Repo.all()
    |> Enum.map(fn object -> {object.name, object.id} end)
  end

  defp override_field_type(user) do
    case CodeFund.Users.has_role?(user.roles, ["admin"]) do
      true -> :number_input
      false -> :hidden_input
    end
  end

  defp override_field_label(user) do
    case CodeFund.Users.has_role?(user.roles, ["admin"]) do
      true -> "Revenue Rate (override)"
      false -> ""
    end
  end

  defp set_overrate_revenue_rate_default(%Sponsorship{
         override_revenue_rate: override_revenue_rate
       })
       when not is_nil(override_revenue_rate),
       do: override_revenue_rate

  defp set_overrate_revenue_rate_default(%Sponsorship{user: %User{revenue_rate: revenue_rate}})
       when not is_nil(revenue_rate),
       do: revenue_rate

  defp set_overrate_revenue_rate_default(_), do: 0.5
end
