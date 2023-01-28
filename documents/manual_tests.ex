import Ecto.Query

Efl.Repo.delete_all(Efl.Dadi)
Efl.Dadi.Category.create_all_items

Efl.Dadi.Post.update_contents

Efl.Xls.Dadi.create_xls

Efl.Mailer.send_email_with_xls

# Fetch a single category

cat = %Efl.RefCategory{
  name: "STORE_RENT",
  display_name: "店铺转让",
  url: "/27.page",
  page_size: 2
}

Efl.Dadi.Category.create_items(cat)

# MySQL commands
select * from proxies order by score desc;
delete from proxies where score=0;
update proxies set score=10 where updated_at > '2022-01-20' and score = 0;
