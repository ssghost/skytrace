use crate::{authentication::Authentication, errors::CustomError};
use axum::{
    extract::Extension,
    response::{IntoResponse, Redirect},
    routing::get,
    Router,
};
use db::{queries, types, Pool};

pub static INDEX: &str = "/app/post_registration";

pub fn routes() -> Router {
    Router::new().route(INDEX, get(post_registration))
}

// After a user has logged in or registered, check they have an entry in
// the organisation table. If not, then create one.
pub async fn post_registration(
    current_user: Authentication,
    Extension(pool): Extension<Pool>,
) -> Result<impl IntoResponse, CustomError> {
    // Create a transaction and setup RLS
    let mut client = pool.get().await?;
    let transaction = client.transaction().await?;
    super::rls::set_row_level_security_user(&transaction, &current_user).await?;

    let org = queries::organisations::get_primary_organisation()
        .bind(&transaction, &current_user.user_id)
        .one()
        .await;

    if let Ok(org) = org {
        Ok(Redirect::to(&crate::routes::space_objects::index_route(
            org.id,
        )))
    } else {
        let inserted_org_id = queries::organisations::insert_organisation()
            .bind(&transaction)
            .one()
            .await?;

        let roles = vec![
            types::public::Role::Administrator,
            types::public::Role::Negotiator,
            types::public::Role::Collaborator,
        ];

        queries::organisations::add_user_to_organisation()
            .bind(
                &transaction,
                &current_user.user_id,
                &inserted_org_id,
                &roles.as_ref(),
            )
            .await?;

        transaction.commit().await?;

        Ok(Redirect::to(&crate::routes::space_objects::index_route(
            inserted_org_id,
        )))
    }
}
