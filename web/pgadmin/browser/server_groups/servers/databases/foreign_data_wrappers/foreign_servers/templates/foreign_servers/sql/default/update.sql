{% import 'macros/privilege.macros' as PRIVILEGE %}
{% if data %}
{% if (data.fsrvtype is defined and data.fsrvtype != o_data.fsrvtype) or (data.fdwname is defined and data.fdwname != o_data.fdwname) %}
{% set fsrvtype = o_data.fsrvtype %}
{% set fdwname = o_data.fdwname %}
{% if data.fsrvtype is defined %}
{% set fsrvtype = data.fsrvtype %}
{% endif %}
{% if data.fdwname is defined %}
{% set fdwname = data.fdwname %}
{% endif %}
-- WARNING:
-- We have found the difference in SERVER TYPE OR FOREIGN DATA WRAPPER
-- so we need to drop the existing foreign server first and re-create it.
DROP SERVER {{ conn|qtIdent(o_data.name) }};

CREATE SERVER {{ conn|qtIdent(o_data.name) }}{% if data.fsrvtype or o_data.fsrvtype %}

    TYPE {{ fsrvtype|qtLiteral }}{% endif %}{% if o_data.fsrvversion %}

    VERSION {{ o_data.fsrvversion|qtLiteral }}{%-endif %}{% if o_data.fdwname %}

    FOREIGN DATA WRAPPER {{ conn|qtIdent(fdwname) }}{% endif %}{% if o_data.fsrvoptions %}

    OPTIONS ({% for variable in o_data.fsrvoptions %}{% if loop.index != 1 %}, {% endif %}
{{ conn|qtIdent(variable.fsrvoption) }} {{ variable.fsrvvalue|qtLiteral }}{% endfor %}){% endif %};

{% else %}
{# ============= Update foreign server name ============= #}
{% if data.name != o_data.name %}
ALTER SERVER {{ conn|qtIdent(o_data.name) }}
    RENAME TO {{ conn|qtIdent(data.name) }};

{% endif %}
{% endif %}
{# ============= Update foreign server owner ============= #}
{% if data.fsrvowner and data.fsrvowner != o_data.fsrvowner %}
ALTER SERVER {{ conn|qtIdent(data.name) }}
    OWNER TO {{ conn|qtIdent(data.fsrvowner) }};

{% endif %}
{# ============= Update foreign server version ============= #}
{% if data.fsrvversion is defined and data.fsrvversion != o_data.fsrvversion %}
ALTER SERVER {{ conn|qtIdent(data.name) }}
    VERSION {{ data.fsrvversion|qtLiteral }};

{% endif %}
{# ============= Update foreign server comments ============= #}
{% if data.description is defined and data.description != o_data.description %}
COMMENT ON SERVER {{ conn|qtIdent(data.name) }}
    IS {{ data.description|qtLiteral }};

{% endif %}
{# ============= Update foreign server options and values ============= #}
{% if data.fsrvoptions and data.fsrvoptions.deleted and data.fsrvoptions.deleted|length > 0 %}
ALTER SERVER {{ conn|qtIdent(data.name) }}
    OPTIONS ({% for variable in data.fsrvoptions.deleted %}{% if loop.index != 1 %}, {% endif %}
DROP {{ conn|qtIdent(variable.fsrvoption) }}{% endfor %}
);

{% endif %}
{% if data.fsrvoptions and data.fsrvoptions.added %}
{% if is_valid_added_options %}
ALTER SERVER {{ conn|qtIdent(data.name) }}
    OPTIONS ({% for variable in data.fsrvoptions.added %}{% if loop.index != 1 %}, {% endif %}
ADD {{ conn|qtIdent(variable.fsrvoption) }} {{ variable.fsrvvalue|qtLiteral }}{% endfor %}
);

{% endif %}
{% endif %}
{% if data.fsrvoptions and data.fsrvoptions.changed %}
{% if is_valid_changed_options %}
ALTER SERVER {{ conn|qtIdent(data.name) }}
    OPTIONS ({% for variable in data.fsrvoptions.changed %}{% if loop.index != 1 %}, {% endif %}
SET {{ conn|qtIdent(variable.fsrvoption) }} {{ variable.fsrvvalue|qtLiteral }}{% endfor %}
);

{% endif %}
{% endif %}
{# Change the privileges #}
{% if data.fsrvacl %}
{% if 'deleted' in data.fsrvacl %}
{% for priv in data.fsrvacl.deleted %}
{{ PRIVILEGE.RESETALL(conn, 'FOREIGN SERVER', priv.grantee, data.name) }}
{% endfor %}
{% endif %}
{% if 'changed' in data.fsrvacl %}
{% for priv in data.fsrvacl.changed %}
{{ PRIVILEGE.RESETALL(conn, 'FOREIGN SERVER', priv.grantee, data.name) }}
{{ PRIVILEGE.APPLY(conn, 'FOREIGN SERVER', priv.grantee, data.name, priv.without_grant, priv.with_grant) }}
{% endfor %}
{% endif %}
{% if 'added' in data.fsrvacl %}
{% for priv in data.fsrvacl.added %}
{{ PRIVILEGE.APPLY(conn, 'FOREIGN SERVER', priv.grantee, data.name, priv.without_grant, priv.with_grant) }}
{% endfor %}
{% endif %}
{% endif %}

{% endif %}
