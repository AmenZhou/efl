[
  mappings: [
    "efl.ecto_repos": [
      doc: "Provide documentation for efl.ecto_repos here.",
      to: "efl.ecto_repos",
      datatype: [
        list: :atom
      ],
      default: [
        Efl.Repo
      ]
    ],
    "efl.Elixir.Efl.Endpoint.url.host": [
      doc: "Provide documentation for efl.Elixir.Efl.Endpoint.url.host here.",
      to: "efl.Elixir.Efl.Endpoint.url.host",
      datatype: :binary,
      default: "localhost"
    ],
    "efl.Elixir.Efl.Endpoint.secret_key_base": [
      doc: "Provide documentation for efl.Elixir.Efl.Endpoint.secret_key_base here.",
      to: "efl.Elixir.Efl.Endpoint.secret_key_base",
      datatype: :binary,
      default: "rb1/HYHuCiIqol5wDRX1lZHGRkMGzZ1P4a9KYXd+1vondVXLVLQFaV9lX3AkswnW"
    ],
    "efl.Elixir.Efl.Endpoint.render_errors.view": [
      doc: "Provide documentation for efl.Elixir.Efl.Endpoint.render_errors.view here.",
      to: "efl.Elixir.Efl.Endpoint.render_errors.view",
      datatype: :atom,
      default: Efl.ErrorView
    ],
    "efl.Elixir.Efl.Endpoint.render_errors.accepts": [
      doc: "Provide documentation for efl.Elixir.Efl.Endpoint.render_errors.accepts here.",
      to: "efl.Elixir.Efl.Endpoint.render_errors.accepts",
      datatype: [
        list: :binary
      ],
      default: [
        "html",
        "json"
      ]
    ],
    "efl.Elixir.Efl.Endpoint.pubsub.name": [
      doc: "Provide documentation for efl.Elixir.Efl.Endpoint.pubsub.name here.",
      to: "efl.Elixir.Efl.Endpoint.pubsub.name",
      datatype: :atom,
      default: Efl.PubSub
    ],
    "efl.Elixir.Efl.Endpoint.pubsub.adapter": [
      doc: "Provide documentation for efl.Elixir.Efl.Endpoint.pubsub.adapter here.",
      to: "efl.Elixir.Efl.Endpoint.pubsub.adapter",
      datatype: :atom,
      default: Phoenix.PubSub.PG2
    ],
    "efl.Elixir.Efl.Endpoint.http.port": [
      doc: "Provide documentation for efl.Elixir.Efl.Endpoint.http.port here.",
      to: "efl.Elixir.Efl.Endpoint.http.port",
      datatype: :integer,
      default: 4000
    ],
    "efl.Elixir.Efl.Endpoint.cache_static_manifest": [
      doc: "Provide documentation for efl.Elixir.Efl.Endpoint.cache_static_manifest here.",
      to: "efl.Elixir.Efl.Endpoint.cache_static_manifest",
      datatype: :binary,
      default: "priv/static/manifest.json"
    ],
    "efl.Elixir.Efl.Endpoint.server": [
      doc: "Provide documentation for efl.Elixir.Efl.Endpoint.server here.",
      to: "efl.Elixir.Efl.Endpoint.server",
      datatype: :atom,
      default: true
    ],
    "logger.console.format": [
      doc: "Provide documentation for logger.console.format here.",
      to: "logger.console.format",
      datatype: :binary,
      default: """
      $time $metadata[$level] $message
      """
    ],
    "logger.console.metadata": [
      doc: "Provide documentation for logger.console.metadata here.",
      to: "logger.console.metadata",
      datatype: [
        list: :atom
      ],
      default: [
        :request_id
      ]
    ],
    "logger.level": [
      doc: "Provide documentation for logger.level here.",
      to: "logger.level",
      datatype: :atom,
      default: :info
    ],
    "classification_utility.Elixir.ClassificationUtility.Endpoint.secret_key_base": [
      doc: "Provide documentation for classification_utility.Elixir.ClassificationUtility.Endpoint.secret_key_base here.",
      to: "classification_utility.Elixir.ClassificationUtility.Endpoint.secret_key_base",
      datatype: :binary,
      default: "mo/YspOY1qjgZPGMVGp52hL7jOYRJgxf+wZp+UO89o65iCbtrW/gYqp3I1XY0XUW"
    ],
    "classification_utility.Elixir.ClassificationUtility.Repo.adapter": [
      doc: "Provide documentation for classification_utility.Elixir.ClassificationUtility.Repo.adapter here.",
      to: "classification_utility.Elixir.ClassificationUtility.Repo.adapter",
      datatype: :atom,
      default: Ecto.Adapters.MySQL
    ],
    "classification_utility.Elixir.ClassificationUtility.Repo.username": [
      doc: "Provide documentation for classification_utility.Elixir.ClassificationUtility.Repo.username here.",
      to: "classification_utility.Elixir.ClassificationUtility.Repo.username",
      datatype: :binary,
      default: "root"
    ],
    "classification_utility.Elixir.ClassificationUtility.Repo.password": [
      doc: "Provide documentation for classification_utility.Elixir.ClassificationUtility.Repo.password here.",
      to: "classification_utility.Elixir.ClassificationUtility.Repo.password",
      datatype: :binary,
      default: "zf40JQyxTKqKkaiN"
    ],
    "classification_utility.Elixir.ClassificationUtility.Repo.database": [
      doc: "Provide documentation for classification_utility.Elixir.ClassificationUtility.Repo.database here.",
      to: "classification_utility.Elixir.ClassificationUtility.Repo.database",
      datatype: :binary,
      default: "classification_utility_prod"
    ],
    "classification_utility.Elixir.ClassificationUtility.Repo.pool_size": [
      doc: "Provide documentation for classification_utility.Elixir.ClassificationUtility.Repo.pool_size here.",
      to: "classification_utility.Elixir.ClassificationUtility.Repo.pool_size",
      datatype: :integer,
      default: 20
    ],
    "mailgun.mailgun_domain": [
      doc: "Provide documentation for mailgun.mailgun_domain here.",
      to: "mailgun.mailgun_domain",
      datatype: :binary,
      default: "https://api.mailgun.net/v3/sandboxad2a0aa5c6cc4d52a6029ac88d0bb74f.mailgun.org"
    ],
    "mailgun.mailgun_key": [
      doc: "Provide documentation for mailgun.mailgun_key here.",
      to: "mailgun.mailgun_key",
      datatype: :binary,
      default: "key-bbd80a922f3222f4efa4a3247ad6af7b"
    ],
    "mailgun.recipient": [
      doc: "Provide documentation for mailgun.recipient here.",
      to: "mailgun.recipient",
      datatype: :binary,
      default: "chou.amen@gmail.com, joyce.lei@epochtimes.com"
    ]
  ],
  translations: [
  ]
]