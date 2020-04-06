import Ecto.Query

Efl.Repo.delete_all(Efl.Dadi)
Efl.RefCategory |> first |> Efl.Repo.one |> Efl.Dadi.Category.create_items

Efl.Dadi.Post.update_contents

Efl.Xls.Dadi.create_xls

Efl.Mailer.send_email_with_xls
