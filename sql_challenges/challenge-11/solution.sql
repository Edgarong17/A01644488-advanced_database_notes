
-- Create a new Colab cell and write the `Comment` model.

class Comment(Base):
    __tablename__ = "comments"

    id = Column(Integer, primary_key=True)
    task_id = Column(Integer, ForeignKey("tasks.id", ondelete="CASCADE"))
    user_id = Column(Integer, ForeignKey("users.id"))
    content = Column(String, nullable=False)
    created_at = Column(TIMESTAMP, server_default=sa.text("SYSTIMESTAMP"))

    task = relationship("Task", back_populates="comments")
    user = relationship("User")

-- 1. What relationships should `Comment` have?
-- It should have a relationship of 1 to n with the user and another one with the task.
-- 2. Should `Task` have a `comments` relationship?
-- Yes
-- 3. What should happen to comments when a task is deleted?
-- There are 2 options one is make the relationship nullable and just change the relationship to null, 
-- and the other ine which is prederable is to first delete the comments and then the tasks.

--1. What does `upgrade()` do?
-- Upgrade defines the changes that need to be applies to the databse to move the database schema forward to a newer version.
--2. What does `downgrade()` do?
-- Downgrade goes back a version on the changes done on a database through upgrade.
--3. What happens if you downgrade this migration?
-- It should remove the comments table because we are going back to the first version of the schema.


--Write a script that:

--1. Creates a team called `"DevOps"`
--2. Creates a user `"diana_ops"`
--3. Creates 3 tasks with different priorities
--4. Prints task count
--5. Closes one task
--6. Deletes the lowest priority task

from sqlalchemy.orm import Session


with Session(engine) as session:
    devops_team = Team(name="DevOps", description="Manages infrastructure and deployments")
    session.add(devops_team)
    session.commit()
    print(f"Created team: {devops_team}")

    diana_ops = User(
        username="diana_ops",
        email="diana.ops@example.com",
        full_name="Diana",
        team=devops_team
    )
    session.add(diana_ops)
    session.commit()
    print(f" Created user: {diana_ops} in team {devops_team.name}")

    task1 = Task(title="Task1", description="test", assignee=diana_ops, status="high_priority")
    task2 = Task(title="Task2", description="test", assignee=diana_ops, status="medium_priority")
    task3 = Task(title="Task3", description="test", assignee=diana_ops, status="low_priority")

    session.add_all([task1, task2, task3])
    session.commit()
    print("Created 3 tasks for Diana:")
    for task in diana_ops.tasks:
        print(f" {task.title} (Status: {task.status})")

    task_count = session.query(Task).filter(Task.assigned_to == diana_ops.id).count()
    print(f"\n Total tasks for Diana: {task_count}")

    task_to_close = session.query(Task).filter_by(title="Task1").first()
    if task_to_close:
        task_to_close.status = "closed"
        session.add(task_to_close)
        session.commit()
        print(f"Closed task: '{task_to_close.title}'")

    task_to_delete = session.query(Task).filter_by(title="Task3").first()
    if task_to_delete:
        session.delete(task_to_delete)
        session.commit()
        print(f" Deleted task: '{task_to_delete.title}'")

    print("\n Updated tasks for Diana:")
    for task in session.query(Task).filter(Task.assigned_to == diana_ops.id).all():
        print(f"   - {task.title} (Status: {task.status})")

-- 1. What happens to the column?
-- In this case because this column was added with in the last migration then the column will be remove but it will alse remove all the other
-- changes made with the last migration.
-- 2. What happens to the data?
-- All the data stored in that column is lost/deleted.

--Answer briefly:

--1. Why use ORM instead of raw SQL?
-- The use of ORM makes it easier and more intuitive to work with databases as it is more programming oriented insted of needing to write raw SQL which can be more confusing
--2. Why use migrations?
-- Migrations helps to keep control over the database versions and to be able to have security in case of any problem with the database as a rollback could help fix it.
--3. When would you rollback?
--  I would rollback when a migration introduces errors, there is an unwanted change, or when the application breaks.
--4. Difference between `add()` and `commit()`?
-- add() places an object into the session storage, while commit() permanently saves the changes in the database.
--5. Why are relationships useful?
-- Relations help to relate data and allows navigation between entities without manual joins.