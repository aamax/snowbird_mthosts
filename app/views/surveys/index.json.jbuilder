json.array!(@surveys) do |st|
  json.id           st.id
  json.date         st.date
  json.user_id      st.user_id
  json.type1        st.type1
  json.type2        st.type2
  json.user         st.user
end